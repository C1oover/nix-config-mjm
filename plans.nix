let
  sources = import ./npins/patched.nix;
  lib = import "${sources.nixos-small}/lib";

  inherit (lib)
    attrNames
    elem
    filterAttrs
    findFirst
    genAttrs
    groupBy
    mapAttrs
    pipe
    ;

  plans = {
    meta = {
      nixpkgs = {
        default = "nixos-small";
        persephone = "nixos";
        uranus = "nixos";
      };

      specialArgs = {
        inputs = sources;
      };
    };

    defaults = {
      imports = [
        ./modules/nixos/deployment.nix
        ./hosts/common/global/nixos
        ./hosts/common/users/matt
      ];
    };

    inherit hosts;

    plans.default = {
      defaultPhase = "main";
      phases = [
        { name = "main"; }
        {
          name = "dns";
          includeIf = _name: config: config.mjm.dns-server.enable;
        }
        {
          name = "vault";
          includeIf = _name: config: config.mjm.vault.enable;
        }
        {
          name = "ingress";
          includeIf = _name: config: config.mjm.ingress.enable;
        }
      ];
    };
  };

  hostNames = [
    "aether"
    "aion"
    "alecto"
    "arges"
    "brontes"
    "chaos"
    "erebus"
    "helios"
    "hypnos"
    "leto"
    "megaera"
    "persephone"
    "steropes"
    "tisiphone"
    "uranus"
  ];
  mkHost = name: { imports = [ ./hosts/${name} ]; };
  hosts = genAttrs hostNames mkHost;

  evalPlan =
    {
      plan ? "default",
      namesToInclude ? [ ],
    }:
    let
      allPkgs = lib.mapAttrs (_name: path: import path { }) sources;
      json = allPkgs.nixos-small.formats.json { };

      evalNode =
        name: configs:
        let
          nixpkgsKey = plans.meta.nixpkgs.${name} or plans.meta.nixpkgs.default;
          npkgs = allPkgs.${nixpkgsKey};
          evalConfig = import (npkgs.path + "/nixos/lib/eval-config.nix");
        in
        evalConfig {
          modules = [
            plans.defaults
          ] ++ configs;
          specialArgs = {
            inherit name;
            nodes = uncheckedNodes;
          } // plans.meta.specialArgs;
        };

      uncheckedNodes = mapAttrs (
        name: value:
        evalNode name [
          { _module.check = false; }
          value
        ]
      ) plans.hosts;
      nodes = pipe plans.hosts [
        (filterAttrs (name: _value: if namesToInclude == [ ] then true else elem name namesToInclude))
        (mapAttrs (name: value: evalNode name [ value ]))
      ];
      deploymentConfig = mapAttrs (_: v: v.config.deployment) nodes;

      phasesWithNodes =
        plan:
        let
          groupedNodes = groupBy (phaseForNode plan) (attrNames nodes);
        in
        map (p: {
          inherit (p) name;
          nodes = groupedNodes.${p.name} or [ ];
        }) plan.phases;

      phaseForNode =
        plan: name:
        let
          config = nodes.${name}.config;
          defaultPhaseInfo = findFirst (p: p.name == plan.defaultPhase) null plan.phases;
          defaultPhase =
            if defaultPhaseInfo ? excludeIf && defaultPhaseInfo.excludeIf name config then
              { name = ""; }
            else
              defaultPhaseInfo;
        in
        (findFirst (
          p: (!(p ? excludeIf && p.excludeIf name config)) && (p ? includeIf && p.includeIf name config)
        ) defaultPhase plan.phases).name;
    in
    {
      configJson = json.generate "plan-config.json" {
        deployment = deploymentConfig;
        phases = phasesWithNodes plans.plans.${plan};
      };
    }
    // (mapAttrs (_: v: v.config.system.build.toplevel) nodes);
in
evalPlan
