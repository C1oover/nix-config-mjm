{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) genAttrs mkEnableOption mkIf;
  cfg = config.mjm.gitlab;
  secrets = config.mjm.services.gitlab.vault.keys;
in
{
  imports = [ ./vault.nix ];

  options.mjm.gitlab = {
    enable = mkEnableOption "GitLab";
  };

  config = mkIf cfg.enable {
    mjm.services.gitlab = {
      vault = {
        enable = true;
        keys =
          genAttrs
            [
              "aws_access_key_id"
              "aws_secret_access_key"
              "db_key_base"
              "fastmail_password"
              "initial_root_password"
              "openid_connect_secret"
              "openid_connect_signing_key"
              "otp_key_base"
              "pages_api_secret_key"
              "secret_key_base"
            ]
            (name: {
              owner = config.services.gitlab.user;
            });
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

    vault-secrets.wantedBy = [
      "gitlab-config.service"
      "gitlab-pages.service"
      "gitlab-workhorse.service"
    ];

    ingress.virtualHosts = {
      git = {
        upstream.service.name = "gitlab";

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
        secretFile = secrets.secret_key_base.path;
        dbFile = secrets.db_key_base.path;
        otpFile = secrets.otp_key_base.path;
        jwsFile = secrets.openid_connect_signing_key.path;
      };
      initialRootPasswordFile = secrets.initial_root_password.path;

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
            aws_access_key_id._secret = secrets.aws_access_key_id.path;
            aws_secret_access_key._secret = secrets.aws_secret_access_key.path;
          };
        };
      };

      smtp = {
        enable = true;
        address = "smtp.fastmail.com";
        port = 465;
        username = "matt@mattmoriarity.com";
        passwordFile = secrets.fastmail_password.path;
        enableStartTLSAuto = false;
        tls = true;
      };

      extraConfig = {
        gitlab = {
          trusted_proxies = [
            "10.0.0.3"
            "10.0.0.4"
            "2601:282:167f:d062:dea6:32ff:fed5:d840"
            "2601:282:167f:d062:dea6:32ff:fe96:bc05"
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
            aws_access_key_id._secret = secrets.aws_access_key_id.path;
            aws_secret_access_key._secret = secrets.aws_secret_access_key.path;
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
          # auto_sign_in_with_provider = "openid_connect";
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
                  identifier = "gitlab";
                  secret._secret = secrets.openid_connect_secret.path;
                  redirect_uri = "https://git.midna.dev/users/auth/openid_connect/callback";
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

    services.caddy = {
      enable = true;
      globalConfig = ''
        auto_https off
        servers {
          trusted_proxies static 10.0.0.3 10.0.0.4 2601:282:167f:d062:dea6:32ff:fed5:d840 2601:282:167f:d062:dea6:32ff:fe96:bc05
        }
      '';
      virtualHosts.":80" = {
        extraConfig = ''
          reverse_proxy unix//run/gitlab/gitlab-workhorse.socket {
            header_up Host git.midna.dev:443
            header_up X-Forwarded-Proto https
          }
        '';
      };
    };

    networking.firewall.allowedTCPPorts = [
      80
      8090
    ];

    services.consul.services = {
      gitlab = {
        port = 80;

        checks.up = {
          http.path = "/-/readiness";
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
  };
}
