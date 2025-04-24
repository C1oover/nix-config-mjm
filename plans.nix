let
  hostNames = [
    "aion"
    "alecto"
    "apollo"
    "arges"
    "artemis"
    "brontes"
    "chaos"
    "demeter"
    "hades"
    "helios"
    "hypnos"
    "leto"
    "megaera"
    "melinoe"
    "niobe"
    "persephone"
    "steropes"
    "tisiphone"
    "uranus"
  ];

  darwinHostNames = [
    "athena"
    "mars"
    "talos"
  ];

  plans = {
    nixos = {
      meta = {
        nixpkgs = {
          default = "nixos-small";
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
