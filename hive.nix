let
  inputs = import ./npins;
  lib = import "${inputs.nixpkgs}/lib";
in
{
  meta = {
    nixpkgs = inputs.nixos;
    specialArgs = {
      inherit inputs;
    };
  };

  defaults =
    { config, lib, ... }:
    {
      options.deployment.phase = lib.mkOption {
        type = lib.types.enum [
          null
          "main"
          "ingress"
        ];
        default = "main";
      };

      config = {
        deployment = {
          targetHost = lib.mkDefault "${config.networking.hostName}.home.mattmoriarity.com";
          targetUser = "matt";
          tags = lib.mkIf (config.deployment.phase != null) [ "phase-${config.deployment.phase}" ];
        };
      };
    };
}
//
  lib.genAttrs
    [
      "aion"
      "alecto"
      "arges"
      "brontes"
      "chaos"
      "cronus"
      "helios"
      "hypnos"
      "leto"
      "megaera"
      "persephone"
      "rhea"
      "steropes"
      "tisiphone"
      "uranus"
    ]
    (name: {
      imports = [ ./hosts/${name} ];
    })
