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
  pulumiGo = pulumi.withPackages (p: [ p.pulumi-go ]);
in

buildGoModule {
  pname = "dippy";
  version = "0.1.0";

  src = ./.;

  vendorHash = "sha256-bT79LvTnOyB0N1ElnEVySdtRKDSuEwIv73Ww4EyjV7w=";

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
