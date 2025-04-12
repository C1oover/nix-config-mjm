{
  lib,
  stdenvNoCC,
  requireFile,
  unzip,
}:
stdenvNoCC.mkDerivation rec {
  pname = "pragmata-pro";
  version = "0.9";

  src =
    (requireFile {
      name = "PragmataPro0.9-8svlok.zip";
      url = "https://fsd.it/shop/fonts/pragmatapro/";
      # This hash can be determined with:
      #   nix hash file ${name}
      hash = "sha256-MXjpDNUyAzMDj7CdOXLag+UOGU03AtAMjsrVtfXnV50=";
    }).overrideAttrs
      { allowSubstitutes = true; };

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
