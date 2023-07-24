{
  ingress.virtualHosts.nomad = {
    upstream = {
      service.name = "http.nomad";
      ipHash = true;
    };

    extraLocationConfig = ''
      # Nomad blocking queries will remain open for a default of 5 minutes.
      # Increase the proxy timeout to accommodate this timeout with an
      # additional grace period.
      proxy_read_timeout 310s;

      # The default Origin header will be the proxy address, which
      # will be rejected by Nomad. It must be rewritten to be the
      # host address instead.
      proxy_set_header Origin "$''${scheme}://$''${proxy_host}";
    '';
  };
}
