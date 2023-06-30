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

  nix.distributedBuilds = true;

  nix.buildMachines = [
    {
      hostName = "hypnos";
      system = "x86_64-linux";
      protocol = "ssh-ng";
      maxJobs = 4;
      supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
      mandatoryFeatures = [];
      publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUtuL3VmVVZ4YURkVEVsZ3M2MXhmdnNIc0huM1J3cEw3bjZETzVxY0JPMEsgcm9vdEBoeXBub3MK";
    }
  ];

  age.secrets.id_nixremote.file = ../../../secrets/nixremote-key.age;
}
