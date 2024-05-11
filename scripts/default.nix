{
  lib,
  stdenvNoCC,
  nushell,
  makeWrapper,
  npins,
  git,
}:
stdenvNoCC.mkDerivation {
  pname = "scripts";
  version = "0.0.1";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = [ nushell ];

  installPhase = ''
    install -Dv ci-update-pins.nu $out/bin/ci-update-pins
    wrapProgram $out/bin/ci-update-pins \
      --prefix PATH : ${
        lib.makeBinPath [
          npins
          git
        ]
      }
  '';

  passthru.scripts = [ "ci-update-pins" ];
}
