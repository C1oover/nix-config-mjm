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
        let
          tailwind = self'.packages.homelab.tailwind;
          esbuild = self'.packages.homelab.esbuild;
        in
        {
          imports = [ ../../modules/devenv/vault-secrets.nix ];

          env.OTEL_SERVICE_NAME = "homelab";
          env.OTEL_EXPORTER_OTLP_ENDPOINT = "http://tempo.service.consul:14318";
          env.OTEL_RESOURCE_ATTRIBUTES = "deployment.environment=dev";
          env.TASKRC =
            (pkgs.writeText "homelab-dev-taskrc" ''
              data.location=${config.env.DEVENV_STATE}/taskwarrior

              uda.reminder_id.type=string
              uda.reminder_id.label=Reminder

              uda.next_notification.type=date
              uda.next_notification.label=Notify
            '').outPath;
          env.RESTIC_PASSWORD_FILE = config.vault-secrets.services.homelab.keys.restic_password.path;

          env.MIX_TAILWIND_PATH = "${lib.getExe' tailwind "tailwind"}";
          env.MIX_TAILWIND_VERSION = tailwind.version;
          env.MIX_ESBUILD_PATH = "${lib.getExe esbuild}";
          env.MIX_ESBUILD_VERSION = esbuild.version;

          vault-secrets = {
            services.homelab.keys = {
              gitlab_token = { };
              netbox_token = { };
              paperless_token = { };
              restic_password = { };
            };
            common.backups.keys = {
              garage_key_id = { };
              garage_secret_key = { };
              b2_key_id = { };
              b2_application_key = { };
            };
          };

          languages.elixir.enable = true;
          languages.erlang.enable = true;
          languages.javascript.enable = true;

          packages =
            with pkgs;
            [
              mix2nix
              node2nix
              restic
              esbuild
              tailwind
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
