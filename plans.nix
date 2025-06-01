let
  hostNames = [
    "persephone"
  ];

  darwinHostNames = [ ];

  plans = {
    nixos = {
      meta = {
        nixpkgs = {
          default = "nixos-small";
          persephone = "nixos";
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
          includeIf = _name: config: config.cloover.vault.enable;
        }
        {
          name = "ingress";
          includeIf = _name: config: config.cloover.ingress.enable;
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
