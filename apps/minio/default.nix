{
  minio = {
    enable = true;
    server = "minio.service.consul:9000";
  };

  ingress.virtualHosts = {
    minio = {
      upstream.service.name = "minio";

      external = true;
      enableAuthProxy = false;
      proxyWebsockets = false;

      extraServerConfig = ''
        # To allow special characters in headers
        ignore_invalid_headers off;
      '';

      extraLocationConfig = ''
        proxy_connect_timeout 300;
        proxy_set_header Connection "";
        chunked_transfer_encoding off;
      '';
    };

    minio-console = {
      upstream.service.name = "minio-console";

      external = true;
      enableAuthProxy = false;

      extraServerConfig = ''
        # To allow special characters in headers
        ignore_invalid_headers off;
      '';

      extraLocationConfig = ''
        proxy_connect_timeout 300;
      '';
    };
  };
}
