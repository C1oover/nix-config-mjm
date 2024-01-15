{
  imports = [
    ./hardware-configuration.nix
    ./impermanence.nix

    ../common/global/nixos
    ../common/users/matt

    ../common/optional/server
    ../common/optional/consul-agent.nix
    ../common/optional/garage.nix

    ./services/actual.nix
    ./services/attic.nix
    ./services/authelia.nix
    ./services/home-assistant.nix
    ./services/lldap.nix
    ./services/netbox.nix
    ./services/paperless.nix
    ./services/prometheus
    ./services/taskserver.nix
    ./services/vault-agent.nix
  ];

  nixpkgs.overlays = [
    (final: prev: {
      pythonPackagesExtensions =
        prev.pythonPackagesExtensions
        ++ [
          (pythonFinal: pythonPrev: {
            # https://github.com/NixOS/nixpkgs/pull/280707
            python3-saml = pythonPrev.python3-saml.overridePythonAttrs {doCheck = false;};
            # https://github.com/NixOS/nixpkgs/pull/280764
            dj-rest-auth = pythonPrev.dj-rest-auth.overridePythonAttrs {
              patches = [];
              doCheck = false;
            };
          })
        ];
    })
  ];

  networking.hostName = "leto";

  boot.supportedFilesystems = ["xfs"];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.qemuGuest.enable = true;

  system.stateVersion = "24.05";
}
