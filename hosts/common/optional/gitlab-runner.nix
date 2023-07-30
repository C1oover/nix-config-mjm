{
  config,
  lib,
  pkgs,
  ...
}: {
  age.secrets."gitlab-runner-registration.env" = {
    file = ../../../secrets/gitlab-runner-registration.age;
  };

  boot.kernel.sysctl."net.ipv4.ip_forward" = true;
  virtualisation.docker.enable = true;
  services.gitlab-runner = {
    enable = true;
    settings = {
      concurrent = 5;
    };
    services = {
      nix = with lib; {
        registrationConfigFile = config.age.secrets."gitlab-runner-registration.env".path;
        # temporary: remove when invalid host issue is fixed
        registrationFlags = ["--docker-host tcp://127.0.0.1:2375"];
        dockerImage = "alpine";
        dockerVolumes = [
          "/nix/store:/nix/store:ro"
          "/nix/var/nix/db:/nix/var/nix/db:ro"
          "/nix/var/nix/daemon-socket:/nix/var/nix/daemon-socket:ro"
          "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
          "/var/cache/bazel:/var/cache/bazel:rw"
        ];
        dockerDisableCache = true;
        preBuildScript = pkgs.writeScript "setup-container" ''
          mkdir -p -m 0755 /nix/var/log/nix/drvs
          mkdir -p -m 0755 /nix/var/nix/gcroots
          mkdir -p -m 0755 /nix/var/nix/profiles
          mkdir -p -m 0755 /nix/var/nix/temproots
          mkdir -p -m 0755 /nix/var/nix/userpool
          mkdir -p -m 1777 /nix/var/nix/gcroots/per-user
          mkdir -p -m 1777 /nix/var/nix/profiles/per-user
          mkdir -p -m 0755 /nix/var/nix/profiles/per-user/root
          mkdir -p -m 0700 "$HOME/.nix-defexpr"
          . ${pkgs.nix}/etc/profile.d/nix-daemon.sh
          ${pkgs.nix}/bin/nix-env -i ${concatStringsSep " " (with pkgs; [nix cacert git openssh glibcLocalesUtf8])}
          ${pkgs.nix}/bin/nix-channel --add https://nixos.org/channels/nixos-unstable nixpkgs
          ${pkgs.nix}/bin/nix-channel --update nixpkgs
          mkdir -p -m 0755 /etc/nix
          echo "experimental-features = flakes nix-command" > /etc/nix/nix.conf
        '';
        environmentVariables = {
          ENV = "/etc/profile";
          USER = "root";
          LC_ALL = "en_US.UTF-8";
          LANG = "en_US.UTF-8";
          NIX_REMOTE = "daemon";
          PATH = "/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/bin:/sbin:/usr/bin:/usr/sbin";
          NIX_SSL_CERT_FILE = "/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt";
          LOCALE_ARCHIVE = "/nix/var/nix/profiles/default/lib/locale/locale-archive";
        };
        tagList = ["nix" pkgs.stdenv.hostPlatform.linuxArch];
      };
      nix-shell = {
        registrationConfigFile = config.age.secrets."gitlab-runner-registration.env".path;
        executor = "shell";
        tagList = ["nix-shell" pkgs.stdenv.hostPlatform.linuxArch];
        protected = true;
      };
    };
  };

  # temporary: remove when invalid host issue is fixed
  virtualisation.docker.listenOptions = [
    "/run/docker.sock"
    "127.0.0.1:2375"
  ];

  services.openssh.knownHosts = let
    keys = import ../../../secrets/keys.nix;
  in
    builtins.mapAttrs (name: publicKey: {
      inherit publicKey;
      extraHostNames = [
        (
          if name == "nyx"
          then "${name}.mattmoriarity.com"
          else "${name}.home.mattmoriarity.com"
        )
      ];
    })
    keys.servers;
}
