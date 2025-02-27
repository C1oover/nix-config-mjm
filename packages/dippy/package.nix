{
  lib,
  buildGoModule,
  attic-client,
  makeWrapper,
  nix-eval-jobs,
  nix-output-monitor,
  nvd-json,
  nvd,
}:

buildGoModule {
  pname = "dippy";
  version = "0.1.0";

  src = ./.;

  vendorHash = "sha256-XMGc52gNAlmGBENVT8Kbvm+YcGsEeOGpcpcS4s8JCp4=";

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
        ]
      }
  '';

  meta.mainProgram = "dippy";
}
