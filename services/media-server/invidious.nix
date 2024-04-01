{ config, lib, ... }:
let
  inherit (lib) mkIf;
  cfg = config.mjm.media-server;
in
{
  config = mkIf cfg.enable {
    mjm.postgresql.enable = true;
    mjm.state.directories = [ "/var/lib/private/invidious" ];

    nixpkgs.overlays = [
      (final: prev: {
        invidious = prev.invidious.overrideAttrs (_oldAttrs: {
          src = prev.fetchFromGitHub {
            owner = "iv-org";
            repo = "invidious";
            fetchSubmodules = true;
            rev = "08390acd0c17875fddb84cabba54197a5b5740e4";
            sha256 = "sha256-75C/ImX/PYikVdSO4rZM/aYyEgx6pU90BHNeRFfcsDM=";
          };
        });
      })
    ];

    services.invidious = {
      enable = true;
      domain = "tube.midna.dev";
      settings = {
        db.user = "invidious";
        external_port = 443;
        https_only = true;
      };
    };

    networking.firewall.allowedTCPPorts = [ config.services.invidious.port ];

    services.consul.services.invidious = {
      inherit (config.services.invidious) port;

      checks = [
        {
          name = "invidious is ready";
          http = "http://localhost:${toString config.services.invidious.port}/";
          interval = "15s";
          timeout = "10s";
        }
      ];
    };
  };
}
