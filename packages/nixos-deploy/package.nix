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

  vendorHash = "sha256-mSOAI5uzrt8K2U7e+VbX/TINuaV4CUswY7ywxitflfE=";

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
