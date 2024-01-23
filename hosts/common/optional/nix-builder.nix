{
  users.users.nixremote = {
    createHome = true;
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKB3J2f/UEHC0+QnqOvhAPdPyjV+OhhRgWaB9aApKbRL"
    ];
  };

  nix.settings.trusted-users = [ "nixremote" ];
}
