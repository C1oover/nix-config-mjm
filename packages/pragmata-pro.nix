{
  lib,
  stdenvNoCC,
  requireFile,
  unzip,
}:
stdenvNoCC.mkDerivation rec {
  pname = "pragmata-pro";
  version = "0.829";

  src = requireFile {
    name = "PragmataPro0.829-ptikme.zip";
    url = "https://fsd.it/shop/fonts/pragmatapro/";
    hash = "sha256-/DgsOMHi/bAE55SDgf5f59q81yvuVERSn/K5Y+D3Pyw=";
  };

  sourceRoot = "PragmataPro${version}";

  nativeBuildInputs = [unzip];

  installPhase = ''

    runHook preInstall

    install -Dm644 */*.otf -t $out/share/fonts/opentype
    install -Dm644 *.ttf -t $out/share/fonts/truetype

    runHook postInstall
  '';

  meta = with lib; {
    description = "A condensed monospaced font optimized for screen";
    homepage = "https://fsd.it/shop/fonts/pragmatapro/";
    license = licenses.unfree;
    maintainers = [];
    platforms = platforms.all;
  };
}
