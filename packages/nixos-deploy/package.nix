{
  lib,
  buildGoModule,
  attic-client,
  makeWrapper,
  nix-eval-jobs,
  nix-output-monitor,
  nvd-json,
}:

buildGoModule {
  pname = "nixos-deploy";
  version = "0.1.0";

  src = ./.;

  vendorHash = "sha256-YSktHeo1HCDhwD0L27ZNgL3AiZs0E+MnOEZE9STRMgI=";

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram $out/bin/nixos-deploy \
      --prefix PATH : ${
        lib.makeBinPath [
          nix-eval-jobs
          nix-output-monitor
          nvd-json
          attic-client
        ]
      }
  '';

  meta.mainProgram = "nixos-deploy";
}
