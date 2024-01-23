{ config, pkgs, ... }:
let
  sshAuthSock = "${config.home.homeDirectory}/.yubikey-agent.sock";
  logFile = "${config.home.homeDirectory}/Library/Logs/yubikey-agent.log";
in
{
  # package in the environment is needed to set up the key
  home.packages = [ pkgs.yubikey-agent ];

  home.sessionVariables.SSH_AUTH_SOCK = sshAuthSock;
  programs.nushell.environmentVariables.SSH_AUTH_SOCK = sshAuthSock;

  launchd = {
    enable = true;

    agents."com.mattmoriarity.yubikey-agent" = {
      enable = true;
      config = {
        KeepAlive = true;
        Label = "com.mattmoriarity.yubikey-agent";
        ProgramArguments = [
          "${pkgs.yubikey-agent}/bin/yubikey-agent"
          "-l"
          sshAuthSock
        ];
        RunAtLoad = true;
        StandardErrorPath = logFile;
        StandardOutPath = logFile;
      };
    };
  };
}
