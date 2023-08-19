{
  terraform.required_providers.gitlab = {
    source = "gitlabhq/gitlab";
    version = ">= 1.0.0";
  };

  provider.gitlab = {
    base_url = "https://git.midna.dev/api/v4/";
  };

  minio.buckets = {
    "gitlab-artifacts" = {};
    "gitlab-ci-secure-files" = {};
    "gitlab-container-registry" = {};
    "gitlab-dependency-proxy" = {};
    "gitlab-external-diffs" = {};
    "gitlab-lfs" = {};
    "gitlab-packages" = {};
    "gitlab-pages" = {};
    "gitlab-terraform-state" = {};
    "gitlab-uploads" = {};
  };

  minio.iamPolicies.gitlab = {
    users = ["gitlab"];
    document = {
      statement = [
        {
          actions = ["s3:*"];
          resources = [
            "arn:aws:s3:::gitlab-*"
          ];
        }
      ];
    };
  };

  vault.policies.gitlab.text = ''
    path "ssh-client-signer/sign/homelab-client" {
      capabilities = ["update"]
    }

    # Allow reading the Ansible vault password
    path "kv/data/deploy" {
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

  ingress.virtualHosts = {
    containers = {
      upstream.addresses = ["10.0.2.32:5050"];

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

    gitlab = {
      upstream.addresses = ["10.0.2.32"];

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
      upstream.addresses = ["10.0.2.32"];

      external = true;

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

    pages = {
      upstream.addresses = ["10.0.2.32:1080"];

      external = true;
      serverAliases = ["*.pages.midna.dev"];

      enableAuthProxy = false;
    };
  };
}
