{
  services.btrbk.instances.btrbk = {
    onCalendar = "daily";
    settings = {
      snapshot_preserve_min = "2d";
      snapshot_preserve = "14d";
      volume."/mnt" = {
        snapshot_dir = "snapshots";
        subvolume."home" = { };
        subvolume."persist" = { };
      };
    };
  };

  systemd.tmpfiles.rules = [ "d /mnt 0755 root root - -" ];

  systemd.services.btrbk-btrbk = {
    preStart = ''
      sudo mount /dev/lvm/root /mnt
    '';
    postStop = ''
      sudo umount /mnt
    '';
  };

  security.sudo.extraRules = [
    {
      users = [ "btrbk" ];
      commands = [
        {
          command = "/run/wrappers/bin/mount";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/wrappers/bin/umount";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
