let
  all = [
    "create"
    "read"
    "update"
    "delete"
    "list"
    "sudo"
  ];
in
{
  vault.policies.repo-nix-config = {
    paths = {
      "kv/data/prod/repos/nix-config".capabilities = [ "read" ];

      "ssh-client-signer/sign/homelab-client".capabilities = [ "update" ];

      "sys/policies/acl/*".capabilities = all;
      "auth/*".capabilities = all;
      "sys/auth/*".capabilities = [
        "create"
        "update"
        "delete"
        "sudo"
      ];
      "sys/auth".capabilities = [ "read" ];
      "sys/mounts/*".capabilities = all;
      "sys/mounts".capabilities = [ "read" ];
      "ssh-client-signer/*".capabilities = all;
      "identity/*".capabilities = all;
    };
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
