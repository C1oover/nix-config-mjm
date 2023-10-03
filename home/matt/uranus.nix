{lib, ...}: {
  imports = [
    ./global

    ./features/controku
    ./features/homelab
  ];

  programs.git.extraConfig = {
    credential = {
      helper = lib.mkForce "/mnt/c/Program\\ Files/Git/mingw64/bin/git-credential-manager.exe";
      credentialStore = lib.mkForce "wincredman";
    };
  };
}
