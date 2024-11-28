{
  lib,
  stdenvNoCC,
  requireFile,
  unzip,
}:
stdenvNoCC.mkDerivation rec {
  pname = "pragmata-pro";
  version = "0.830";

  src = requireFile {
    name = "PP-ep6wq.zip";
    url = "https://fsd.it/shop/fonts/pragmatapro/";
    sha256 = "0cna4wavnhnb8j8vg119ap8mqkckx04z2gms2hsz4daywc51ghr8";
  };

  sourceRoot = "PragmataPro${version}";

  nativeBuildInputs = [ unzip ];

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
    maintainers = [ ];
    platforms = platforms.all;
  };
}
