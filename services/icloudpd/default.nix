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
in
{
  options.mjm.icloudpd = {
    enable = mkEnableOption "iCloud photos downloader";
  };

  config = mkIf cfg.enable {
    mjm.services.icloudpd = { };
    mjm.state.services = [ "icloudpd" ];

    systemd.services.icloudpd = {
      enable = false;
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      environment = {
        HOME = "/var/lib/icloudpd";
      };
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        ExecStart = utils.escapeSystemdExecArgs [
          (lib.getExe pkgs.icloudpd)
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
          ${lib.getExe pkgs.icloudpd} \
          "$@"
      '')
    ];
  };
}
