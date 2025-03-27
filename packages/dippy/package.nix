{
  lib,
  buildGoModule,
  attic-client,
  makeWrapper,
  fetchzip,
  lix,
  nix-eval-jobs,
  nix-output-monitor,
  nvd-json,
  nvd,
  pulumi,
}:

let
  pulumiGo = pulumi.withPackages (p: [ p.pulumi-language-go ]);
  lix-eval-jobs = (nix-eval-jobs.override { nix = lix; }).overrideAttrs (oldAttrs: {
    src = fetchzip {
      url = "https://git.lix.systems/api/v1/repos/lix-project/nix-eval-jobs/archive/f8869bdcca7c1d5aaf37de3da3a4176811279a57.tar.gz?rev=f8869bdcca7c1d5aaf37de3da3a4176811279a57";
      hash = "sha256-F/RvI9chHywnckEqHO1ggjzCayknhDnnl2kNnnVXpWg=";
    };
    version = "2.91.0-lix-f8869bd";

    mesonBuildType = "debugoptimized";

    ninjaFlags = oldAttrs.ninjaFlags or [ ] ++ [ "-v" ];
  });
in

buildGoModule {
  pname = "dippy";
  version = "0.1.0";

  src = ./.;

  vendorHash = "sha256-o9WMyxpTcCkfulsc6myp5Fuv4jNoizlA3Eb+iJSnH3A=";

  excludedPackages = [ "./sdks/desec" ];

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram $out/bin/dippy \
      --prefix PATH : ${
        lib.makeBinPath [
          lix-eval-jobs
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
