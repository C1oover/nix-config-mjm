upstream ingress {
  {{ range service "ingress-http" }}
  server {{ .NodeMeta.tailscale_ip }};
  {{ else }}
  server 127.0.0.1:65535;
  {{ end }}
}
