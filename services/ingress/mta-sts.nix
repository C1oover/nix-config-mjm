{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.mjm.ingress;
in
{
  config = mkIf cfg.enable {
    services.caddy.settings.apps.http.servers.default.routes = [
      {
        match = [
          {
            host = [
              "mta-sts.midna.dev"
              "mta-sts.mattmoriarity.com"
            ];
          }
        ];
        handle = [
          {
            handler = "file_server";
            root = pkgs.writeTextFile {
              name = "mta-sts-root";
              destination = "/.well-known/mta-sts.txt";
              text = ''
                version: STSv1
                mode: enforce
                mx: in1-smtp.messagingengine.com
                mx: in2-smtp.messagingengine.com
                max_age: 2419200
              '';
            };
          }
        ];
      }
    ];
  };
}
