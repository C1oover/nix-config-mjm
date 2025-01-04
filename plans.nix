let
  evalPlan = import ./lib/deploy.nix;
  sources = import ./npins/patched.nix;

  localModulesPath = toString ./modules;

  hostNames = [
    "aion"
    "alecto"
    "apollo"
    "arges"
    "artemis"
    "brontes"
    "chaos"
    "hades"
    "helios"
    "hypnos"
    "leto"
    "megaera"
    "persephone"
    "steropes"
    "tisiphone"
    "uranus"
  ];

  plans = {
    meta = {
      nixpkgs = {
        default = "nixos-small";
        persephone = "nixos";
        uranus = "nixos";
      };

      specialArgs = {
        inputs = sources;
        inherit localModulesPath;
      };
    };

    defaults = {
      imports = [ "${localModulesPath}/nixos" ];
    };

    inherit hosts;

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

  mkHost = name: { imports = [ ./hosts/${name} ]; };
  hosts = builtins.listToAttrs (
    map (name: {
      inherit name;
      value = mkHost name;
    }) hostNames
  );
in
evalPlan plans
