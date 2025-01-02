import ../lib/overlay-patches.nix {
  # bcachefs-fstab-generator
  nixos."345207".hash = "sha256-tI+wlhyC2e63NirN2kgg1I4GMPvMwFTIFFyo2nR1MDQ=";

  # python312Packages.strawberry-graphql: fix build
  nixos-small."370062".hash = "sha256-9kb52QEBB6nK6lejTOxtm10Hg8h+ejUoSqY3kxSeJnc=";

  # consul: init
  darwin."1245".hash = "sha256-JqxFVDVTJIUVADbXgulIenqZeknxahZvQ7hb554Tkzs=";

  # Add TPM support
  proxmox."111".hash = "sha256-RXrtvvM3AYRB4lotkHSdmN7reKycGJWIlUL5gI3NAuE=";
  # pve-storage: add XML::LibXML dep
  proxmox."112".hash = "sha256-LnyOOCnIvqVHw1i+R+b/ahkjccm8WdYhv3O3od5aS64=";
  # Get backups working
  proxmox."113".hash = "sha256-gyFxI+UaxLGTVUgMESKVDl8OsMxm4UXz1nAglVQgeU8=";
}
