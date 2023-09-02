{lib, ...}: {
  imports = [
    ./global

    ./features/homelab
  ];

  programs.git.extraConfig = {
    credential = {
      credentialStore = lib.mkForce "plaintext";
    };
  };
}
