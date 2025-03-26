{
  lib,
  buildGoModule,
  attic-client,
  makeWrapper,
  nix-eval-jobs,
  nix-output-monitor,
  nvd-json,
  nvd,
  pulumi,
}:

let
  pulumiGo = pulumi.withPackages (p: [ p.pulumi-language-go ]);
in

buildGoModule {
  pname = "dippy";
  version = "0.1.0";

  src = ./.;

  vendorHash = "sha256-3IinAAjoyMJwdXz366MhzqHbAAXu4MdOdXF0WZrQ7Lg=";

  excludedPackages = [ "./sdks/desec" ];

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram $out/bin/dippy \
      --prefix PATH : ${
        lib.makeBinPath [
          nix-eval-jobs
          nix-output-monitor
          nvd-json
          nvd
          attic-client
          pulumiGo
        ]
      }
  '';

  meta.mainProgram = "dippy";
}
