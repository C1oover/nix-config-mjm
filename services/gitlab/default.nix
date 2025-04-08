{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.gitlab;

  mkCred = name: "gitlab_${name}:${config.mjm.services.gitlab.vault.socketPath}";
  secretPath = svc: name: "/run/credentials/gitlab-${svc}.service/gitlab_${name}";

  clientId = "jVwrh7Lz6flakzaT6oLJJPAhRnyvLey0X33kVDVurMUAVPcfVPnrEt9XnBAoCE5r";
  redirectUri = "https://git.midna.dev/users/auth/openid_connect/callback";
in
{
  options.mjm.gitlab = {
    enable = mkEnableOption "GitLab";
  };

  config = mkIf cfg.enable {
    mjm.services.gitlab = {
      vault = {
        enable = true;
        useSpiffeIdentity = true;
      };
    };
    mjm.postgresql.enable = true;
    mjm.state.directories = [
      {
        directory = config.services.gitlab.statePath;
        inherit (config.services.gitlab) user group;
      }
    ];
    mjm.state.services = [ "redis-gitlab" ];

    ingress.virtualHosts = {
      git = {
        upstream = {
          service.name = "gitlab";
          tls.enable = true;
        };

        enableAuthProxy = false;
        useIPv4Proxy = true;
      };
      pages = {
        upstream.service.name = "gitlab-pages";

        serverAliases = [
          "*.pages.midna.dev"
          "www.midna.dev"
          "midna.dev"
        ];

        enableAuthProxy = false;
        useIPv4Proxy = true;

        extraRoutes = [
          {
            match = [ { path = [ "/.well-known/matrix/server" ]; } ];
            handle = [
              {
                handler = "static_response";
                body = builtins.toJSON { "m.server" = "chat.midna.dev:443"; };
              }
            ];
          }
          {
            match = [ { path = [ "/.well-known/matrix/client" ]; } ];
            handle = [
              {
                handler = "headers";
                response.set.Access-Control-Allow-Origin = [ "*" ];
              }
              {
                handler = "static_response";
                body = builtins.toJSON {
                  "m.homeserver".base_url = "https://chat.midna.dev/";
                  "org.matrix.msc3575.proxy".url = "https://chat.midna.dev";
                };
              }
            ];
          }
        ];
      };
    };

    services.gitlab = {
      enable = true;
      packages.gitlab = pkgs.gitlab-ee;
      host = "git.midna.dev";
      port = 443;
      https = true;

      secrets = {
        secretFile = secretPath "config" "secret_key_base";
        dbFile = secretPath "config" "db_key_base";
        otpFile = secretPath "config" "otp_key_base";
        jwsFile = secretPath "config" "openid_connect_signing_key";
      };
      initialRootPasswordFile = secretPath "db-config" "initial_root_password";

      pages = {
        enable = true;
        settings = {
          pages-domain = "pages.midna.dev";
          listen-proxy = [ ":8090" ];
          pages-status = "/healthz";
        };
      };

      workhorse.config = {
        object_storage = {
          provider = "AWS";
          s3 = {
            aws_access_key_id._secret = secretPath "workhorse" "aws_access_key_id";
            aws_secret_access_key._secret = secretPath "workhorse" "aws_secret_access_key";
          };
        };
      };

      smtp = {
        enable = true;
        address = "smtp.fastmail.com";
        port = 465;
        username = "matt@mattmoriarity.com";
        passwordFile = secretPath "config" "fastmail_password";
        enableStartTLSAuto = false;
        tls = true;
      };

      extraConfig = {
        gitlab = {
          trusted_proxies = [
            "10.0.0.3"
            "10.0.0.4"
            "${config.mjm.ipv6Prefix}:dea6:32ff:fed5:d840"
            "${config.mjm.ipv6Prefix}:dea6:32ff:fe96:bc05"
          ];
          email_from = "gitlab@matt.mattmoriarity.com";
          email_display_name = "GitLab (midna.dev)";
          email_reply_to = "noreply@matt.mattmoriarity.com";
        };

        object_store = {
          enabled = true;
          proxy_download = true;
          connection = {
            provider = "AWS";
            aws_access_key_id._secret = secretPath "config" "aws_access_key_id";
            aws_secret_access_key._secret = secretPath "config" "aws_secret_access_key";
            region = "home";
            endpoint = "http://garage.service.consul:3902";
            path_style = true;
          };
          objects = {
            artifacts.bucket = "gitlab-artifacts";
            ci_secure_files.bucket = "gitlab-ci-secure-files";
            dependency_proxy.bucket = "gitlab-dependency-proxy";
            external_diffs.bucket = "gitlab-external-diffs";
            lfs.bucket = "gitlab-lfs";
            packages.bucket = "gitlab-packages";
            pages.bucket = "gitlab-pages";
            terraform_state.bucket = "gitlab-terraform-state";
            uploads.bucket = "gitlab-uploads";
          };
        };

        omniauth = {
          enabled = true;
          auto_sign_in_with_provider = "openid_connect";
          allow_single_sign_on = [ "openid_connect" ];
          auto_link_user = [ "openid_connect" ];
          providers = [
            {
              name = "openid_connect";
              label = "Authelia";
              icon = "https://www.authelia.com/images/branding/logo-cropped.png";
              args = {
                name = "openid_connect";
                strategy_class = "OmniAuth::Strategies::OpenIDConnect";
                scope = [
                  "openid"
                  "profile"
                  "email"
                  "groups"
                ];
                response_type = "code";
                response_mode = "query";
                issuer = "https://auth.midna.dev";
                discovery = true;
                client_auth_method = "basic";
                uid_field = "preferred_username";
                send_scope_to_token_endpoint = true;
                pkce = true;
                client_options = {
                  identifier = clientId;
                  secret._secret = secretPath "config" "managed__oidc_client_secret";
                  redirect_uri = redirectUri;
                  gitlab = {
                    groups_attribute = "groups";
                    admin_groups = [ "admins" ];
                  };
                };
              };
            }
          ];
        };
      };
    };

    systemd.services.gitlab-config.serviceConfig.LoadCredential = map mkCred [
      "secret_key_base"
      "db_key_base"
      "otp_key_base"
      "openid_connect_signing_key"
      "managed__oidc_client_secret"
      "aws_access_key_id"
      "aws_secret_access_key"
      "fastmail_password"
    ];
    systemd.services.gitlab-db-config.serviceConfig.LoadCredential = [
      (mkCred "initial_root_password")
    ];
    systemd.services.gitlab-workhorse.serviceConfig.LoadCredential = map mkCred [
      "aws_access_key_id"
      "aws_secret_access_key"
    ];

    mjm.authelia.oidcClients.gitlab = {
      name = "GitLab";
      inherit clientId;
      clientSecret = "$argon2id$v=19$m=65536,t=3,p=4$TSJDgCxch+ahWCQ0KNi51Q$K40y7dODVjPjV//jVemSSL8n2FuQqEm8Mwo8sqLNTXw";
      redirectUris = [ redirectUri ];
    };

    mjm.spire.tunnels.gitlab = {
      mode = "server";
      port = 8443;
      target = "unix:/run/gitlab/gitlab-workhorse.socket";
      allowIngress = true;
    };

    networking.firewall.allowedTCPPorts = [
      80
      8090
    ];

    services.consul.services = {
      gitlab = {
        port = 8443;

        checks.up = {
          http.path = "/-/readiness";
          http.socket = "/run/gitlab/gitlab-workhorse.socket";
        };
      };
      gitlab-pages = {
        port = 8090;

        checks.up = {
          http.path = "/healthz";
        };
      };
    };

    deployment.rebootAutomatically = false;
    deployment.consulChecks = [
      "gitlab"
      "gitlab-pages"
    ];
    deployment.tests = {
      inherit (pkgs.nixosTests) gitlab;
    };
  };
}
