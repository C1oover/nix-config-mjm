{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrValues
    concatMapStringsSep
    concatStringsSep
    mkAfter
    mkEnableOption
    mkForce
    mkIf
    ;
  cfg = config.mjm.gitlab-runner;
  secrets = config.mjm.services.gitlab-runner.vault.keys;
  nix = config.nix.package;
in
{
  options.mjm.gitlab-runner = {
    enable = mkEnableOption "GitLab CI runner";
  };

  config = mkIf cfg.enable {
    mjm.services.gitlab-runner = {
      vault = {
        enable = true;
        keys.remote_builder_private_key = { };
      };
    };
    mjm.state.directories = [
      {
        directory = "/var/lib/private/gitlab-runner";
        user = "nobody";
        group = "nogroup";
      }
    ];

    vault-secrets.wantedBy = [ "gitlab-runner.service" ];
    vault-secrets.templates.gitlab-runner-docker-env.text = ''
      CI_SERVER_URL=https://git.midna.dev
      CI_SERVER_TOKEN={{ with secret "kv/prod/services/gitlab-runner" }}{{ .Data.data.nix_docker_auth_token }}{{ end }}
    '';

    boot.kernel.sysctl."net.ipv4.ip_forward" = true;

    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
      dockerSocket.enable = true;
      defaultNetwork.settings = {
        dns_enabled = true;
        ipv6_enabled = true;
        subnets = [
          {
            gateway = "10.88.0.1";
            subnet = "10.88.0.0/16";
          }
          {
            gateway = "fd00::1";
            subnet = "fd00::/80";
          }
        ];
      };
    };
    # gitlab-runner will enable this by default, but we want podman instead
    virtualisation.docker.enable = false;

    # without this, when podman changes, it will be restarted, which will kill the build
    # in the middle of restarting services and leave things in a bad state.
    systemd.services.podman.restartIfChanged = false;

    # run a GC weekly in the middle of the night
    nix.gc.dates = "Mon *-*-* 11:00:00";

    services.gitlab-runner = {
      enable = true;
      settings = {
        concurrent = 5;
      };
      services = {
        nix = {
          authenticationTokenConfigFile = config.vault-secrets.templates.gitlab-runner-docker-env.path;
          registrationFlags = [
            "--output-limit 102400"
            "--docker-enable-ipv6"
          ];
          dockerImage = "alpine";
          dockerVolumes = [
            # dynamic persistent storage
            "/root/.cache/nix"
            "/root/.pulumi"

            # bind mounts from host
            "/nix/store:/nix/store:ro"
            "/nix/var/nix/db:/nix/var/nix/db:ro"
            "/nix/var/nix/daemon-socket:/nix/var/nix/daemon-socket:ro"
            "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
            "/etc/ssh/ssh_known_hosts:/etc/ssh/ssh_known_hosts:ro"
          ];
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
            . ${nix}/etc/profile.d/nix-daemon.sh
            ${nix}/bin/nix-env -i ${
              concatStringsSep " " (attrValues {
                inherit nix;
                inherit (pkgs)
                  cacert
                  git
                  glibcLocalesUtf8
                  jujutsu
                  openssh
                  ;
                inherit (pkgs.scripts) update-fork;
              })
            }
            mkdir -p /etc/nix
            ln -sf ${pkgs.writeText "nix.conf" ''
              experimental-features = nix-command flakes
            ''} /etc/nix/nix.conf
            ${nix}/bin/nix-channel --add https://nixos.org/channels/nixos-unstable nixpkgs
            ${nix}/bin/nix-channel --update nixpkgs
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
            FF_NETWORK_PER_BUILD = "true";
          };
        };
      };
    };

    # you would think all the config below shouldn't be here because the builds
    # run in a container, but you'd be wrong. because the container uses the
    # host's nix-daemon, that is what is performing the builds. so the host's
    # settings for SSH and Nix config are what matters.

    programs.ssh.extraConfig = mkAfter ''
      Host ${concatMapStringsSep " " (m: m.hostName) config.nix.buildMachines}
        IdentitiesOnly yes
        IdentityFile ${secrets.remote_builder_private_key.path}
    '';

    # force nixos tests to use a remote builder
    nix.settings.system-features = mkForce [
      "benchmark"
      "big-parallel"
    ];

    nix.distributedBuilds = true;
    nix.buildMachines =
      let
        mkVmTestBuilder = name: {
          hostName = "${name}.home.mattmoriarity.com";
          system = "x86_64-linux";
          protocol = "ssh-ng";
          maxJobs = 2;
          speedFactor = 1;
          supportedFeatures = [
            "kvm"
            "nixos-test"
          ];
          mandatoryFeatures = [ "nixos-test" ];
        };
      in
      [
        {
          hostName = "arges.home.mattmoriarity.com";
          sshUser = "matt";
          system = "aarch64-linux";
          protocol = "ssh-ng";
          maxJobs = 4;
          speedFactor = 2;
          supportedFeatures = [
            "nixos-test"
            "benchmark"
            "big-parallel"
            "kvm"
          ];
          mandatoryFeatures = [ ];
          publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSURTM3BQTkVhSEEreWNEYTdrVHlOU3hzQVlCRlpJN1lNd2VEcnJOMEdnK2wgcm9vdEBuaXhvcwo=";
        }
        (mkVmTestBuilder "hades" // { maxJobs = 1; })
      ]
      ++ (map mkVmTestBuilder [
        "apollo"
        "artemis"
        "demeter"
      ]);
  };
}
