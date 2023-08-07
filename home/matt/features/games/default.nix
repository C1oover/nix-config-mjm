{pkgs, ...}: {
  home.packages = with pkgs; [
    dolphinEmuMaster
    lutris
  ];
}
