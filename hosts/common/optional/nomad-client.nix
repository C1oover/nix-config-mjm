{ pkgs, ... }: {
  services.nomad = {
    enable = true;
    dropPrivileges = false;
    extraPackages = [ pkgs.cni-plugins ];
    settings = {
      client = {
        enabled = true;
        meta = {
          "connect.sidecar_image" = "envoyproxy/envoy:v1.22.5";
        };
      };
      plugins = [
        {
          docker = {
            config = {
              infra_image = "rancher/pause:3.2";
              allow_privileged = true;
              allow_caps = [ "CHOWN" "DAC_OVERRIDE" "FSETID" "FOWNER" "MKNOD" "NET_RAW" "NET_ADMIN" "SETGID" "SETUID" "SETFCAP" "SETPCAP" "NET_BIND_SERVICE" "SYS_CHROOT" "KILL" "AUDIT_WRITE" ];

              volumes = {
                enabled = true;
              };
            };
          };
        }
      ];
    };
  };

  networking.firewall.allowedTCPPorts = [
    4646
    4647
  ];

  networking.firewall.allowedTCPPortRanges = [
    {
      from = 20000;
      to = 32000;
    }
  ];
}
