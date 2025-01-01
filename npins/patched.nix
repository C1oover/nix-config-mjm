import ../lib/overlay-patches.nix {
  # bcachefs-fstab-generator
  nixos."345207".hash = "sha256-tI+wlhyC2e63NirN2kgg1I4GMPvMwFTIFFyo2nR1MDQ=";

  # netbox: 4.1.3 -> 4.1.10
  nixos-small."368036".hash = "sha256-IYad1H2y8VOvVrpolPEAiZ+R2RVCozZtuGHOC8E/ZFA=";

  # consul: init
  darwin."1245".hash = "sha256-JqxFVDVTJIUVADbXgulIenqZeknxahZvQ7hb554Tkzs=";

  # Add TPM support
  proxmox."111".hash = "sha256-RXrtvvM3AYRB4lotkHSdmN7reKycGJWIlUL5gI3NAuE=";
  # pve-storage: add XML::LibXML dep
  proxmox."112".hash = "sha256-LnyOOCnIvqVHw1i+R+b/ahkjccm8WdYhv3O3od5aS64=";
  # Get backups working
  proxmox."113".hash = "sha256-oUNaZtZIP94tYJrZ/pn2/CoFOdQBDRVWAwF23IMxzNg=";
}
