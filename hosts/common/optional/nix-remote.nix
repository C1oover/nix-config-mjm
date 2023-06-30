{
  pkgs,
  config,
  ...
}: let
  sshConfig = pkgs.writeText "root-ssh-config" ''
    Host hypnos
        # Prevent using ssh-agent or another keyfile, useful for testing
        IdentitiesOnly yes
        IdentityFile ${config.age.secrets.id_nixremote.path}
        User nixremote
  '';
in {
  system.activationScripts.nixremote-ssh-config.text = ''
    mkdir -p /root/.ssh
    ln -sf ${sshConfig} /root/.ssh/config
  '';

  age.secrets.id_nixremote.file = ../../../secrets/nixremote-key.age;
}
