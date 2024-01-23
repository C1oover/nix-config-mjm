{ lib, ... }:
{
  imports = [
    ./global

    ./features/controku
    ./features/helix
    ./features/homelab
    ./features/taskwarrior
  ];

  programs.git.extraConfig = {
    credential = {
      helper = lib.mkForce "/mnt/c/Program\\ Files/Git/mingw64/bin/git-credential-manager.exe";
      credentialStore = lib.mkForce "wincredman";
    };
  };
}
