{lib, ...}: {
  imports = [
    ./global
  ];

  programs.git.extraConfig = {
    credential = {
      credentialStore = lib.mkForce "plaintext";
    };
  };
}
