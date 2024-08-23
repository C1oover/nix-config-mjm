{ buildGoModule, caddy }:

buildGoModule rec {
  pname = "caddy";
  version = "2.8.4";

  src = ./.;

  vendorHash = "sha256-153v07SsO2zf0mwUZInm1R7RuNu8We1U1jQXGT+XvhU=";

  overrideModAttrs = _: {
    postBuild = ''
      sed -i -e '392i if rec.Name == "" {\nrec.Name = "@"\n}' vendor/github.com/caddyserver/certmagic/solvers.go
    '';
  };

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
