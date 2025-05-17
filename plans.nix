let
  hostNames = [
    "aion"
    "apollo"
    "arges"
    "artemis"
    "athena"
    "brontes"
    "chaos"
    "demeter"
    "hades"
    "hypnos"
    "leto"
    "niobe"
    "persephone"
    "steropes"
    "uranus"
  ];

  darwinHostNames = [
    "mars"
    "talos"
  ];

  plans = {
    nixos = {
      meta = {
        nixpkgs = {
          default = "nixos-small";
          athena = "nixos";
          persephone = "nixos";
          uranus = "nixos";
        };

        inherit specialArgs;
      };

      defaults = "${localModulesPath}/nixos";
      inherit hosts;
    };

    darwin = {
      meta = {
        nixpkgs.default = "nixpkgs";
        inherit specialArgs;
      };

      defaults = "${localModulesPath}/darwin";
      hosts = darwinHosts;
    };

    plans.default = {
      defaultPhase = "main";
      phases = [
        { name = "main"; }
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

  evalPlan = import ./packages/dippy/deploy.nix;
  sources = import ./npins;

  localModulesPath = toString ./modules;
  specialArgs = {
    inputs = sources;
    hostConfig = null;
    inherit localModulesPath;
  };

  hosts = builtins.listToAttrs (
    map (name: {
      inherit name;
      value = ./hosts/${name};
    }) hostNames
  );
  darwinHosts = builtins.listToAttrs (
    map (name: {
      inherit name;
      value = ./hosts/${name};
    }) darwinHostNames
  );
in
evalPlan plans
