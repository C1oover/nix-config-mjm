{
  vault.databases.roles.lldap = {
    ttl = "long";
  };

  vault.policies.lldap.text = ''
    path "database/creds/lldap" {
      capabilities = ["read"]
    }
  '';

  vault.databases.roles.authelia = {
    ttl = "long";
  };

  vault.policies.authelia.text = ''
    path "kv/data/authelia" {
      capabilities = ["read"]
    }

    path "database/creds/authelia" {
      capabilities = ["read"]
    }
  '';

  vault.approles.roles.leto.tokenPolicies = ["lldap" "authelia"];

  ingress.virtualHosts = {
    auth = {
      upstream.service.name = "authelia";

      external = true;
      enableAuthProxy = false;
      recommendedProxySettings = false;

      extraServerConfig = ''
        location /api/verify {
          proxy_pass http://auth;
        }
      '';

      extraLocationConfig = ''
        ## Headers
        proxy_set_header Host $host;
        proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $http_host;
        proxy_set_header X-Forwarded-Uri $request_uri;
        proxy_set_header X-Forwarded-Ssl on;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Connection "";

        ## Basic Proxy Configuration
        client_body_buffer_size 128k;
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503; ## Timeout if the real server is dead.
        proxy_redirect  http://  $scheme://;
        proxy_cache_bypass $cookie_session;
        proxy_no_cache $cookie_session;
        proxy_buffers 64 256k;

        ## Trusted Proxies Configuration
        ## Please read the following documentation before configuring this:
        ##     https://www.authelia.com/integration/proxies/nginx/#trusted-proxies
        # set_real_ip_from 10.0.0.0/8;
        # set_real_ip_from 172.16.0.0/12;
        # set_real_ip_from 192.168.0.0/16;
        # set_real_ip_from fc00::/7;
        set_real_ip_from 10.0.0.2;
        set_real_ip_from 10.0.0.3;
        set_real_ip_from 10.0.0.4;
        real_ip_header X-Forwarded-For;
        real_ip_recursive on;

        ## Advanced Proxy Configuration
        send_timeout 5m;
        proxy_read_timeout 360;
        proxy_send_timeout 360;
        proxy_connect_timeout 360;
      '';
    };

    users = {
      upstream.service.name = "lldap";
      external = true;
      enableAuthProxy = false;
    };
  };
}
