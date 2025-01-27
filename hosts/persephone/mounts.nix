{
  boot.initrd.systemd.mounts = [
    {
      what = "/dev/disk/by-partlabel/persist";
      where = "/persist";
      type = "bcachefs";
      after = [ "bcachefs-unlock@dev-disk-by\\x2dpartlabel-persist.service" ];
      requires = [ "bcachefs-unlock@dev-disk-by\\x2dpartlabel-persist.service" ];
    }
    {
      what = "/persist/@root";
      where = "/sysroot";
      options = "bind";
    }
  ];

  boot.initrd.systemd.services.rollback-root = {
    wantedBy = [ "initrd.target" ];
    after = [ "persist.mount" ];
    requires = [ "persist.mount" ];
    before = [ "sysroot.mount" ];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/bin/sh -c 'bcachefs subvolume delete /persist/@root; bcachefs subvolume snapshot /persist/@root-blank /persist/@root'";
    };
  };
}
