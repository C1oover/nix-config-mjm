{
  perSystem =
    {
      system,
      pkgs,
      lib,
      inputs',
      self',
      ...
    }:
    {
      packages.homelab = pkgs.callPackage ./package.nix { };

      devenv.shells.homelab =
        { config, ... }:
        {
          env.OTEL_SERVICE_NAME = "homelab";
          env.OTEL_EXPORTER_OTLP_ENDPOINT = "https://api.honeycomb.io:443";
          env.TASKRC =
            (pkgs.writeText "homelab-dev-taskrc" ''
              data.location=${config.env.DEVENV_STATE}/taskwarrior

              uda.reminder_id.type=string
              uda.reminder_id.label=Reminder

              uda.next_notification.type=date
              uda.next_notification.label=Notify
            '').outPath;

          languages.elixir.enable = true;
          languages.erlang.enable = true;
          languages.javascript.enable = true;

          packages =
            with pkgs;
            [
              mix2nix
              node2nix
            ]
            ++ (lib.optional stdenv.isLinux inotify-tools);

          services.postgres = {
            enable = true;
            initialDatabases = [ { name = "homelab_dev"; } ];
          };

          services.caddy = {
            enable = true;
            config = ''
              {
                http_port 6002
              }

              localhost:5002 {
                reverse_proxy :4002
                tls internal
              }
            '';
          };

          processes.phx-server.exec = "mix ecto.migrate && elixir --sname dev -S mix phx.server";

          dotenv.disableHint = true;
        };

      apps.set-version.program = lib.getExe (
        pkgs.writeShellApplication {
          name = "set-version";
          runtimeInputs = [ pkgs.gnused ];
          text = ''
            NEW_VERSION="$1"
            sed -e "/APP VERSION/s/version = \".*\";/version = \"$NEW_VERSION\";/" -i default.nix
          '';
        }
      );
    };
}
