{
  systemd.services.nixos-upgrade = {
    description = "NixOS Upgrade";

    restartIfChanged = false;
    unitConfig.X-StopOnRemoval = false;

    serviceConfig.Type = "oneshot";

    environment =
      config.nix.envVars
      // {
        inherit (config.environment.sessionVariables) NIX_PATH;
        HOME = "/root";
      }
      // config.networking.proxy.envVars;

    path = with pkgs; [
      coreutils
      gnutar
      xz.bin
      gzip
      gitMinimal
      config.nix.package.out
      config.programs.ssh.package
    ];

    script =
      let
        nixos-rebuild = "${config.system.build.nixos-rebuild}/bin/nixos-rebuild";
      in
      ''
        ${pkgs.gitMinimal}/bin/git -C /etc/nixos pull
        ${nixos-rebuild} switch --flake /etc/nixos
      '';

    startAt = "*:0,30:*";

    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };

  systemd.timers.nixos-upgrade = {
    timerConfig = {
      RandomizedDelaySec = "10min";
    };
  };
}
