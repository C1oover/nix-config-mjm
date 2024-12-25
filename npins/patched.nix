import ../lib/overlay-patches.nix {
  # bcachefs-fstab-generator
  nixos."345207".hash = "sha256-tI+wlhyC2e63NirN2kgg1I4GMPvMwFTIFFyo2nR1MDQ=";

  # freeipmi: fix build with GCC14
  nixos-small."367923".hash = "sha256-tVe9MHpWDgPBbG+TU+sIjy/DwZQBy3tKzQdMZamD2NA=";

  # netbox: 4.1.3 -> 4.1.10
  nixos-small."368036".hash = "sha256-IYad1H2y8VOvVrpolPEAiZ+R2RVCozZtuGHOC8E/ZFA=";
}
