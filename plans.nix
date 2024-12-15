let
  evalPlan = import ./lib/deploy.nix;
  sources = import ./npins/patched.nix;

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

  mkHost = name: { imports = [ ./hosts/${name} ]; };
  hosts = builtins.listToAttrs (
    map (name: {
      inherit name;
      value = mkHost name;
    }) hostNames
  );
in
evalPlan plans
