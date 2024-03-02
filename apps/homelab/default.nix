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
          env.DEVENV_SECRETS = "${config.env.DEVENV_STATE}/secrets";
          env.RESTIC_PASSWORD_FILE = "${config.env.DEVENV_SECRETS}/restic_password";

          enterShell =
            let
              vault = lib.getExe pkgs.vault;
              getSecret = path: field: "${vault} kv get -mount=kv -field=${field} ${path}";
              writeSecret =
                path: field: filename:
                "${getSecret path field} > $DEVENV_SECRETS/${filename}";
            in
            ''
              export DEVENV_SECRETS="$DEVENV_STATE/secrets"
              mkdir -p $DEVENV_SECRETS

              ${writeSecret "homelab" "restic_password" "restic_password"}
              ${writeSecret "restic" "garage_key_id" "garage_key_id"}
              ${writeSecret "restic" "garage_secret_key" "garage_secret_key"}
              ${writeSecret "restic" "b2_key_id" "b2_key_id"}
              ${writeSecret "restic" "b2_application_key" "b2_application_key"}
            '';

          languages.elixir.enable = true;
          languages.erlang.enable = true;
          languages.javascript.enable = true;

          packages =
            with pkgs;
            [
              mix2nix
              node2nix
              restic
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
