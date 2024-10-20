{
  pkgs,
  lib,
  config,
  utils,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.icloudpd;

  icloudpd = pkgs.icloudpd.overridePythonAttrs (oldAttrs: {
    version = "1.23.4";

    # iowk's commit with the authentication fix
    src = pkgs.fetchFromGitHub {
      owner = "icloud-photos-downloader";
      repo = "icloud_photos_downloader";
      rev = "4bcb2ac46a585205cbf3886b3df78179b34b18b1";
      hash = "sha256-uc93aKt/4oGwY9HByw2u08pBIhHcplEhzu6W8RJ33ts=";
    };

    propagatedBuildInputs =
      oldAttrs.propagatedBuildInputs
      ++ (builtins.attrValues {
        inherit (pkgs.python3Packages) flask srp waitress;
      });

    doCheck = false;
  });
in
{
  options.mjm.icloudpd = {
    enable = mkEnableOption "iCloud photos downloader";
  };

  config = mkIf cfg.enable {
    mjm.services.icloudpd = { };
    mjm.state.services = [ "icloudpd" ];

    systemd.services.icloudpd = {
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      environment = {
        HOME = "/var/lib/icloudpd";
      };
      serviceConfig = {
        Type = "simple";
        ExecStart = utils.escapeSystemdExecArgs [
          (lib.getExe icloudpd)
          "--directory"
          "/videos/photos"
          "--username"
          "mmoriarity@me.com"
          "--watch-with-interval"
          "1800"
          "--log-level"
          "info"
        ];
        StateDirectory = "icloudpd";
        DynamicUser = true;
        ReadWritePaths = [ "/videos/photos" ];
      };
    };

    environment.systemPackages = [
      (pkgs.writeShellScriptBin "icloudpd" ''
        exec systemd-run \
          --service-type=oneshot \
          -p Environment=HOME=/var/lib/icloudpd \
          -p StateDirectory=icloudpd \
          -p DynamicUser=true \
          -p ReadWritePaths=/videos/photos \
          --wait \
          -qt \
          --collect \
          ${lib.getExe icloudpd} \
          "$@"
      '')
    ];
  };
}
