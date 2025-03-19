{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkAfter
    mkEnableOption
    mkForce
    mkIf
    ;
  cfg = config.mjm.gitlab-runner;
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
    vault-secrets.templates.gitlab-runner-shell-env.text = ''
      CI_SERVER_URL=https://git.midna.dev
      CI_SERVER_TOKEN={{ with secret "kv/prod/services/gitlab-runner" }}{{ .Data.data.nix_shell_auth_token }}{{ end }}
    '';

    boot.kernel.sysctl."net.ipv4.ip_forward" = true;

    virtualisation.docker = {
      enable = true;
      daemon.settings = {
        ipv6 = true;
        fixed-cidr-v6 = "fd00::/80";
        experimental = true;
        ip6tables = true; # requires experimental
      };
    };

    # run a GC weekly in the middle of the night
    nix.gc.dates = "Mon *-*-* 11:00:00";

    services.gitlab-runner = {
      enable = true;
      settings = {
        concurrent = 5;
      };
      services = {
        nix = with lib; {
          authenticationTokenConfigFile = config.vault-secrets.templates.gitlab-runner-docker-env.path;
          registrationFlags = [
            # temporary: remove when invalid host issue is fixed
            "--docker-host tcp://127.0.0.1:2375"
            "--output-limit 102400"
          ];
          dockerImage = "alpine";
          dockerVolumes = [
            "/nix/store:/nix/store:ro"
            "/nix/var/nix/db:/nix/var/nix/db:ro"
            "/nix/var/nix/daemon-socket:/nix/var/nix/daemon-socket:ro"
            "/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt:ro"
            "/etc/ssh/ssh_known_hosts:/etc/ssh/ssh_known_hosts:ro"
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
            ${pkgs.nix}/bin/nix-env -i ${
              concatStringsSep " " (
                with pkgs;
                [
                  nix
                  cacert
                  git
                  openssh
                  glibcLocalesUtf8
                ]
              )
            }
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
        };
        nix-shell = {
          authenticationTokenConfigFile = config.vault-secrets.templates.gitlab-runner-shell-env.path;
          registrationFlags = [ "--output-limit 102400" ];
          executor = "shell";
        };
      };
    };

    environment.systemPackages = [
      # The nix-shell runner needs this to be able to clone repos and evaluate flakes
      pkgs.git
      # Used to push automatic updates to megamerges
      pkgs.jujutsu
      pkgs.scripts.update-fork
    ];

    # If Docker changes, we don't want it to restart during a deploy, because that will cause the deploy
    # to fail, and then we'll just be stuck in that state.
    systemd.services.docker.restartIfChanged = false;

    # temporary: remove when invalid host issue is fixed
    virtualisation.docker.listenOptions = [
      "/run/docker.sock"
      "127.0.0.1:2375"
    ];

    programs.ssh.extraConfig = mkAfter ''
      Host apollo.home.mattmoriarity.com arges.home.mattmoriarity.com artemis.home.mattmoriarity.com hades.home.mattmoriarity.com
        IdentitiesOnly yes
        IdentityFile ${config.mjm.services.gitlab-runner.vault.keys.remote_builder_private_key.path}
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
        (mkVmTestBuilder "apollo" // { maxJobs = 1; })
      ]
      ++ (map mkVmTestBuilder [
        "hades"
        "artemis"
        "demeter"
      ]);
  };
}
