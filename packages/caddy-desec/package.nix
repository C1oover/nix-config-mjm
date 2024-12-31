{ buildGoModule, caddy }:

buildGoModule rec {
  pname = "caddy";
  version = "2.9.0";

  src = ./.;

  vendorHash = "sha256-2dFg5EIMiyMzVHvyU5YisCZYa6hXKrZ4I1REnpkCQcI=";

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];

  # matches upstream since v2.8.0
  tags = [ "nobadger" ];

  postInstall = ''
    mkdir -p $out/lib/systemd/system

    substitute ${caddy}/lib/systemd/system/caddy.service $out/lib/systemd/system/caddy.service \
      --replace-fail ${caddy}/bin/caddy $out/bin/caddy
    substitute ${caddy}/lib/systemd/system/caddy-api.service $out/lib/systemd/system/caddy-api.service \
      --replace-fail ${caddy}/bin/caddy $out/bin/caddy
  '';

  meta.mainProgram = "caddy";
}
