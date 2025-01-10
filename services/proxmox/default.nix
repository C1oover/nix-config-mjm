{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib)
    getExe'
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.mjm.proxmox;

  # Overrides to include the freenas-proxmox plugin patches
  pve-storage = pkgs.pve-storage.overrideAttrs (oldAttrs: {
    postPatch =
      oldAttrs.postPatch
      + ''
        patch PVE/Storage/ZFSPlugin.pm ${inputs.freenas-proxmox}/perl5/PVE/Storage/ZFSPlugin.pm.patch
      '';

    postInstall =
      oldAttrs.postInstall
      + ''
        cp ${inputs.freenas-proxmox}/perl5/PVE/Storage/LunCmd/FreeNAS.pm $out/${pkgs.perl538.libPrefix}/${pkgs.perl538.version}/PVE/Storage/LunCmd/FreeNAS.pm
        mkdir $out/${pkgs.perl538.libPrefix}/${pkgs.perl538.version}/REST
        cp ${inputs.freenas-proxmox}/perl5/REST/Client.pm $out/${pkgs.perl538.libPrefix}/${pkgs.perl538.version}/REST/Client.pm
      '';
  });

  pve-ha-manager = pkgs.pve-ha-manager.override { inherit pve-storage; };
  pve-manager = (pkgs.pve-manager.override { inherit pve-ha-manager; }).overrideAttrs (oldAttrs: {
    # get templates to install to $out/share instead of $out/usr/share
    postPatch =
      oldAttrs.postPatch
      + ''
        sed -i templates/Makefile -e "s,/usr,,"
      '';

    postFixup =
      oldAttrs.postFixup
      + ''
        patch $out/share/pve-manager/js/pvemanagerlib.js ${inputs.freenas-proxmox}/pve-manager/js/pvemanagerlib.js.patch
      '';
  });
in
{
  options.mjm.proxmox = {
    enable = mkEnableOption "Proxmox VE";

    ipAddress = mkOption {
      type = types.str;
    };

    managementInterface = mkOption {
      type = types.str;
    };

    bridgeInterface = mkOption {
      type = types.str;
    };
  };

  config = mkIf cfg.enable {
    mjm.services.proxmox = { };

    ingress.virtualHosts.proxmox = {
      upstream = {
        service.name = "proxmox";
        useSSL = true;
        ipHash = true;
      };

      enableAuthProxy = false;
    };

    # TODO parameterize if I ever have uneven hosts
    boot.kernelParams = [ "zfs.zfs_arc_max=7516192768" ];

    nixpkgs.overlays = [
      (import inputs.proxmox).overlays.x86_64-linux
    ];

    services.proxmox-ve = {
      enable = true;

      package = pkgs.proxmox-ve.override {
        inherit pve-ha-manager pve-manager pve-storage;
      };

      inherit (cfg) ipAddress;
    };

    services.consul.services.proxmox = {
      port = 8006;

      checks.up = {
        http.url = "https://${config.networking.hostName}.home.mattmoriarity.com:8006/";
      };
    };

    deployment.consulChecks = [ "proxmox" ];

    # really don't want an entire VM host rebooting automatically
    deployment.rebootAutomatically = false;

    systemd.network.networks = {
      "10-lan" = {
        matchConfig.Name = cfg.managementInterface;
        # other config for this network is in base module
      };
      "10-lan2" = {
        matchConfig.Name = cfg.bridgeInterface;
        networkConfig.Bridge = "vmbr0";
      };
      "10-lan2-bridge" = {
        matchConfig.Name = "vmbr0";
      };
    };

    systemd.network.netdevs.vmbr0 = {
      netdevConfig = {
        Name = "vmbr0";
        Kind = "bridge";
      };
    };

    hardware.ksm.enable = true;

    # PVE needs a root account with a proper password to work right
    users.users.root.hashedPassword = config.users.users.mjm.hashedPassword;

    systemd.tmpfiles.settings."50-proxmox" = {
      # TODO: remove these once all Proxmox hosts are on NixOS
      "/bin/true"."L+".argument = getExe' pkgs.coreutils "true";
      "/usr/sbin/qm"."L+".argument = "/run/current-system/sw/bin/qm";

      # patching rust dependencies is hard, so for now just symlink this into place
      "/usr/share/pve-manager/templates"."L+".argument = "${pve-manager}/share/pve-manager/templates";
    };

    # TODO: remove once PR #111 does this
    environment.systemPackages = [ pkgs.swtpm ];
    systemd.services.pve-guests.path = [ pkgs.swtpm ];
    systemd.services.qmeventsd.path = [ pkgs.swtpm ];
  };
}
