let
  sources = import ../npins/patched.nix;
  lib = import "${sources.nixos-small}/lib";

  inherit (lib)
    attrNames
    elem
    filterAttrs
    findFirst
    groupBy
    mapAttrs
    pipe
    recurseIntoAttrs
    ;

  evalPlan =
    plans:
    {
      plan ? "default",
      namesToInclude ? [ ],
      tofuNodes ? false,
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

      config = {
        deployment = deploymentConfig;
        phases = phasesWithNodes plans.plans.${plan};
      };
    in
    if tofuNodes then
      nodes
    else
      {
        inherit config;
        configJson = json.generate "plan-config.json" config;
        toplevels = pipe nodes [
          (mapAttrs (_: v: v.config.system.build.toplevel))
          recurseIntoAttrs
        ];
        hosts = nodes;
      };
in
evalPlan
