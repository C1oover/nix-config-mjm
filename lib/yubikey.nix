{ config, pkgs, ... }:

{
  # package in the environment is needed to set up the key
  home.packages = [ pkgs.yubikey-agent ];

  home.sessionVariables.SSH_AUTH_SOCK = "${config.home.homeDirectory}/.yubikey-agent.sock";

  launchd = {
    enable = true;

    agents."com.mattmoriarity.yubikey-agent" = {
      enable = true;
      config = {
        KeepAlive = true;
        Label = "com.mattmoriarity.yubikey-agent";
        ProgramArguments = ["${pkgs.yubikey-agent}/bin/yubikey-agent" "-l" "${config.home.homeDirectory}/.yubikey-agent.sock"];
        RunAtLoad = true;
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/yubikey-agent.log";
        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/yubikey-agent.log";
      };
    };
  };
}
