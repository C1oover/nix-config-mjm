{
  vault.policies.gitlab.text = ''
    path "ssh-client-signer/sign/homelab-client" {
      capabilities = ["update"]
    }

    # Allow reading Attic push token
    path "kv/data/attic/client" {
      capabilities = ["read"]
    }

    # Allow updating Vault policies for apps
    path "sys/policies/acl/*" {
      capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    }

    # Manage auth methods broadly across Vault
    path "auth/*" {
      capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    }

    # Create, update, and delete auth methods
    path "sys/auth/*" {
      capabilities = ["create", "update", "delete", "sudo"]
    }

    # List auth methods
    path "sys/auth" {
      capabilities = ["read"]
    }

    # Manage secrets engines
    path "sys/mounts/*" {
      capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    }

    # List existing secrets engines.
    path "sys/mounts" {
      capabilities = ["read"]
    }

    path "database/roles/*" {
      capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    }

    path "database/config/*" {
      capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    }

    path "database/creds/*" {
      capabilities = ["read"]
    }

    path "ssh-client-signer/*" {
      capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    }

    path "pki-homelab/*" {
      capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    }

    path "identity/*" {
      capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    }
  '';

  vault.policies.gitlab-homelab.text = ''
    # Allow reading Attic push token
    path "kv/data/attic/client" {
      capabilities = ["read"]
    }
  '';

  vault.policies.gitlab-runner = {
    paths."kv/data/gitlab/runner".capabilities = [ "read" ];
    approles = [
      "hypnos"
      "arges"
    ];
  };

  ingress.virtualHosts = {
    containers = {
      upstream.addresses = [ "10.0.2.32:5050" ];

      enableAuthProxy = false;

      extraServerConfig = ''
        # To allow special characters in headers
        ignore_invalid_headers off;
        # Allow any size file to be uploaded.
        proxy_request_buffering off;
        proxy_connect_timeout       300;
        proxy_send_timeout          300;
        proxy_read_timeout          300;
        send_timeout                300;
      '';

      extraLocationConfig = ''
        proxy_redirect off;
      '';
    };

    git = {
      upstream.addresses = [ "10.0.2.32" ];

      enableAuthProxy = false;
      useIPv4Proxy = true;

      extraServerConfig = ''
        # To allow special characters in headers
        ignore_invalid_headers off;
        # Allow any size file to be uploaded.
        proxy_request_buffering off;
        proxy_connect_timeout       300;
        proxy_send_timeout          300;
        proxy_read_timeout          300;
        send_timeout                300;
      '';

      extraLocationConfig = ''
        proxy_redirect off;
      '';
    };

    pages = {
      upstream.addresses = [ "10.0.2.33" ];
      serverAliases = [
        "*.pages.midna.dev"
        "www.midna.dev"
        "midna.dev"
      ];
      enableAuthProxy = false;

      extraServerConfig = ''
        location =/.well-known/matrix/server {
          default_type application/json;
          return 200 '{"m.server": "chat.midna.dev:443"}';
        }

        location =/.well-known/matrix/client {
          default_type application/json;
          add_header Access-Control-Allow-Origin *;
          return 200 '{"m.homeserver": {"base_url": "https://chat.midna.dev/"}}';
        }
      '';
    };
  };
}
