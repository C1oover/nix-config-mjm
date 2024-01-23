{
  pkgs,
  config,
  lib,
  ...
}:
{
  home.packages = with pkgs; [ ngrok ];

  # this doesn't work
  # home.file.".ngrok2/ngrok.yml".source = config.age.secrets."ngrok.yml".path;

  home.activation.write-ngrok-config = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # need to be able to use getconf
    export PATH=$PATH:/usr/bin
    mkdir -p ${config.home.homeDirectory}/.ngrok2
    ln -sf ${config.age.secrets."ngrok.yml".path} ${config.home.homeDirectory}/.ngrok2/ngrok.yml
  '';

  age.secrets."ngrok.yml".file = ../../../../secrets/ngrok.age;
}
