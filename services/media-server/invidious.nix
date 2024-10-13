{ config, lib, ... }:
let
  inherit (lib) mkIf;
  cfg = config.mjm.media-server;
in
{
  config = mkIf cfg.enable {
    mjm.postgresql.enable = true;
    mjm.state.directories = [ "/var/lib/private/invidious" ];

    ingress.virtualHosts.yt = {
      upstream.service.name = "invidious";
      enableAuthProxy = false;
      useIPv4Proxy = true;
    };

    services.invidious = {
      enable = true;
      domain = "yt.midna.dev";
      settings = {
        db.user = "invidious";
        external_port = 443;
        https_only = true;
      };
      extraSettingsFile = "/var/lib/invidious/extra-settings.json";

      sig-helper.enable = true;
    };

    vault-secrets.wantedBy = [ "invidious.service" ];
    vault-secrets.templates.invidious-config.text = ''
      {{ with secret "kv/prod/services/media-server" }}
      {
        "po_token": {{ .Data.data.youtube_po_token | toJSON }},
        "visitor_data": {{ .Data.data.youtube_visitor_data | toJSON }}
      }
      {{ end }}
    '';

    systemd.services.invidious = {
      serviceConfig.LoadCredential = [
        "extra-settings:${config.vault-secrets.templates.invidious-config.path}"
      ];
      preStart = ''
        ln -sf "$CREDENTIALS_DIRECTORY/extra-settings" /var/lib/invidious/extra-settings.json
      '';
    };

    networking.firewall.allowedTCPPorts = [ config.services.invidious.port ];

    services.consul.services.invidious = {
      inherit (config.services.invidious) port;

      checks.up = {
        http.path = "/";
      };
    };
  };
}
