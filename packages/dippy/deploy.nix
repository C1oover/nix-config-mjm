let
  sources = import ../../npins;
  lib = import "${sources.nixos-small}/lib";

  inherit (lib)
    attrNames
    attrValues
    elem
    filter
    filterAttrs
    findFirst
    groupBy
    mapAttrs
    mergeAttrsList
    pipe
    recurseIntoAttrs
    ;

  evalPlan =
    plans:
    {
      plan ? "default",
      namesToInclude ? [ ],
    }:
    let
      allPkgs = lib.mapAttrs (_name: path: import path { }) sources;
      json = allPkgs.nixos-small.formats.json { };

      evalNode = {
        nixos =
          name: configs:
          let
            nixpkgsKey = plans.nixos.meta.nixpkgs.${name} or plans.nixos.meta.nixpkgs.default;
            npkgs = if builtins.isPath nixpkgsKey then import nixpkgsKey { } else allPkgs.${nixpkgsKey};
            evalConfig = import (npkgs.path + "/nixos/lib/eval-config.nix");
          in
          evalConfig {
            modules = [
              plans.nixos.defaults
            ] ++ configs;
            specialArgs = {
              inherit name;
              nodes = uncheckedNodes;
            } // plans.nixos.meta.specialArgs;
          };
        darwin =
          name: configs:
          let
            nixpkgsKey = plans.darwin.meta.nixpkgs.${name} or plans.darwin.meta.nixpkgs.default;
            nixpkgs = sources.${nixpkgsKey};
            evalConfig = import "${sources.darwin}/eval-config.nix";
          in
          evalConfig {
            lib = import "${nixpkgs}/lib";
            modules = configs ++ [
              plans.darwin.defaults
              {
                nixpkgs.source = nixpkgs;
                system.checks.verifyNixPath = false;
              }
            ];
            specialArgs = {
              inherit name;
              nodes = uncheckedNodes;
            } // plans.darwin.meta.specialArgs;
          };
      };

      uncheckedNodes = mapAttrs (
        name: value:
        evalNode.nixos name [
          { _module.check = false; }
          value
        ]
      ) plans.nixos.hosts;
      nodes = pipe plans.nixos.hosts [
        (filterAttrs (name: _value: if namesToInclude == [ ] then true else elem name namesToInclude))
        (mapAttrs (name: value: evalNode.nixos name [ value ]))
      ];
      deploymentConfig = mapAttrs (_: v: removeAttrs v.config.deployment [ "tests" ]) nodes;
      darwinNodes = pipe plans.darwin.hosts [
        (filterAttrs (name: _value: if namesToInclude == [ ] then true else elem name namesToInclude))
        (mapAttrs (name: value: evalNode.darwin name [ value ]))
      ];

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

      infra =
        let
          allNodes = attrValues nodes;
        in
        {
          vhosts = pipe allNodes [
            (filter (n: !n.config.mjm.ingress.enable))
            (map (n: n.config.ingress.virtualHosts))
            mergeAttrsList
            (mapAttrs (_: v: v.useIPv4Proxy))
          ];
          vaultServices = pipe allNodes [
            (map (n: n.config.vault.services))
            mergeAttrsList
            (mapAttrs (_: p: p.paths))
          ];
          vaultPolicies = pipe allNodes [
            (map (n: n.config.vault.policies))
            mergeAttrsList
            (mapAttrs (_: p: builtins.toJSON { path = p.paths; }))
          ];
          vaultRoles = pipe nodes [
            (filterAttrs (_: n: n.config.vault.policies != { } || n.config.vault.services != { }))
            (mapAttrs (
              _: n: {
                policies = attrNames n.config.vault.policies;
                services = attrNames n.config.vault.services;
              }
            ))
          ];
          oidcClients = pipe allNodes [
            (map (n: n.config.mjm.authelia.oidcClients))
            mergeAttrsList
            attrNames
          ];
        };
    in
    {
      inherit config infra;
      configJson = json.generate "plan-config.json" config;
      infraJson = json.generate "infra.json" infra;
      toplevels = pipe (nodes // darwinNodes) [
        (mapAttrs (_: v: v.config.system.build.toplevel))
        recurseIntoAttrs
      ];
      tests = pipe nodes [
        attrValues
        (map (v: v.config.deployment.tests))
        mergeAttrsList
        recurseIntoAttrs
      ];
      hosts = nodes // darwinNodes;
      nixosHosts = nodes;
      darwinHosts = darwinNodes;
    };
in
evalPlan
