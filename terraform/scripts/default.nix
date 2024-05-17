{
  lib,
  stdenvNoCC,
  makeWrapper,
  nushell,
  coreutils,
  vault,
  opentofu,
  terraformConfiguration,
}:

stdenvNoCC.mkDerivation {
  pname = "tofu-scripts";
  version = "0.0.1";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = [ nushell ];

  installPhase = ''
    install -Dv tofu-scripts.nu $out/bin/tofu-scripts

    wrapProgram $out/bin/tofu-scripts \
      --set TF_CONFIG ${terraformConfiguration} \
      --prefix PATH : ${
        lib.makeBinPath [
          coreutils
          opentofu
          vault
        ]
      }
  '';

  meta.mainProgram = "tofu-scripts";
}
