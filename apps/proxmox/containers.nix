let
  nixosTemplate = "local:vztmpl/nixos-system-x86_64-linux.tar.xz";

  mkRootFs = size: {
    inherit size;
    storage = "local-zfs";
  };

  defaultLxc = {
    ostemplate = nixosTemplate;
    arch = "amd64";
    cmode = "console";
    cores = 0;
    cpulimit = 1;
    cpuunits = 100;
    features.nesting = true;
    memory = 2048;
    swap = 0;
    network = [
      {
        name = "eth0";
        ip = "dhcp";
        bridge = "vmbr0";
      }
    ];
    onboot = true;
    ostype = "unmanaged";
    rootfs = mkRootFs "32G";
    unprivileged = true;
    tags = "nixos";
  };
in
{
  terraform.resource.proxmox_lxc = {
    rhea = defaultLxc // {
      target_node = "apollo";
      hostname = "rhea";
      description = ''
        DNS server
      '';
      startup = "order=2,up=30";
    };

    cronus = defaultLxc // {
      target_node = "artemis";
      hostname = "cronus";
      description = ''
        DNS server
      '';
      startup = "order=2,up=30";
    };
  };
}
