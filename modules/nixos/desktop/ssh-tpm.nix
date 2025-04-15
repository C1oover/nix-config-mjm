{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.mjm.desktop;

  askPasswordWrapper = pkgs.writeScript "ssh-askpass-wrapper" ''
    #! ${pkgs.runtimeShell} -e
    eval export $(systemctl --user show-environment | ${lib.getExe pkgs.gnugrep} -E '^(DISPLAY|WAYLAND_DISPLAY|XAUTHORITY)=')
    exec ${config.programs.ssh.askPassword} "$@"
  '';
in
{
  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.ssh-tpm-agent ];

    programs.ssh.enableAskPassword = true;
    security.tpm2.enable = true;

    users.users.${config.mjm.username}.extraGroups = [ config.security.tpm2.tssGroup ];

    systemd.user.sockets.ssh-tpm-agent = {
      wantedBy = [ "sockets.target" ];
      description = "SSH TPM agent socket";
      documentation = [
        "man:ssh-agent(1)"
        "man:ssh-add(1)"
        "man:ssh(1)"
      ];

      socketConfig = {
        ListenStream = "%t/ssh-tpm-agent.sock";
        SocketMode = "0600";
      };
    };

    systemd.user.services.ssh-tpm-agent = {
      requires = [ "ssh-tpm-agent.socket" ];
      description = "ssh-tpm-agent service";
      documentation = [
        "man:ssh-agent(1)"
        "man:ssh-add(1)"
        "man:ssh(1)"
      ];

      unitConfig.ConditionEnvironment = [ "!SSH_AGENT_PID" ];

      environment.SSH_TPM_AUTH_SOCK = "%t/ssh-tpm-agent.sock";
      environment.SSH_ASKPASS = askPasswordWrapper;

      serviceConfig = {
        Type = "simple";
        ExecStart = lib.getExe pkgs.ssh-tpm-agent;
        PassEnvironment = "SSH_AGENT_PID";
        SuccessExitStatus = 2;
      };
    };
  };
}
