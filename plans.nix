let
  sources = import ./npins/patched.nix;
  lib = import "${sources.nixos-small}/lib";

  inherit (lib)
    attrNames
    genAttrs
    groupBy
    findFirst
    mapAttrs
    ;

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

  evalPlans =
    plans:
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
      nodes = mapAttrs (name: value: evalNode name [ value ]) plans.hosts;
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
      inherit nodes deploymentConfig;
      toplevel = mapAttrs (_: v: v.config.system.build.toplevel) nodes;
      deploymentConfigJson = json.generate "deployment.json" deploymentConfig;
      plansJson = mapAttrs (
        name: plan: json.generate "plan-${name}.json" (phasesWithNodes plan)
      ) plans.plans;
    };
in
evalPlans {
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
      {
        name = "main";
        excludeIf = _name: config: config.mjm.desktop.enable;
      }
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
}
