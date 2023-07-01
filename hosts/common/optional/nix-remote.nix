{config, ...}: {
  programs.ssh.extraConfig = ''
    Host hypnos
        # Prevent using ssh-agent or another keyfile, useful for testing
        IdentitiesOnly yes
        IdentityFile ${config.age.secrets.id_nixremote.path}
        User nixremote
  '';

  nix.distributedBuilds = true;

  nix.buildMachines = [
    {
      hostName = "hypnos";
      system = "x86_64-linux";
      protocol = "ssh-ng";
      maxJobs = 4;
      speedFactor = 2;
      supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
      mandatoryFeatures = [];
      publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUtuL3VmVVZ4YURkVEVsZ3M2MXhmdnNIc0huM1J3cEw3bjZETzVxY0JPMEsgcm9vdEBoeXBub3MK";
    }
  ];

  # force all builds to go to the remote builder
  nix.settings.max-jobs = 0;

  age.secrets.id_nixremote.file = ../../../secrets/nixremote-key.age;
}
