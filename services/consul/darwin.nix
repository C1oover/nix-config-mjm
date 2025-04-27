{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.mjm.consul;

  certsConfig = pkgs.writeText "consul-spiffe-helper.hcl" ''
    agent_address = "${config.mjm.spire.agent.socketPath}"
    cmd = "killall"
    cmd_args = "-HUP consul"
    cert_dir = "${cfg.certsPath}"
    daemon_mode = true
    svid_file_name = "cert.pem"
    svid_key_file_name = "key.pem"
    svid_bundle_file_name = "bundle.pem"
  '';
in
{
  imports = [ ./common.nix ];

  config = mkIf cfg.enable {
    mjm.consul.certsPath = "/var/lib/consul";
    
    services.consul.extraConfig.bind_addr = "0.0.0.0";

    launchd.daemons.consul-certs = {
      command = "${pkgs.spiffe-helper}/bin/spiffe-helper -config ${certsConfig}";
      serviceConfig = {
        KeepAlive = true;
        RunAtLoad = true;
        StandardOutPath = "/var/lib/consul/certs.log";
        StandardErrorPath = "/var/lib/consul/certs.log";
        GroupName = "consul";
        UserName = "consul";
      };
    };
  };
}
