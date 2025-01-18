{
  stdenvNoCC,
  appimageTools,
  fetchurl,
}:

let
  pname = "unofficial-homestuck-collection";
  version = "2.5.6";
  src = fetchurl {
    url = "https://github.com/GiovanH/unofficial-homestuck-collection/releases/download/v2.5.6/The-Unofficial-Homestuck-Collection-2.5.6.AppImage";
    hash = "sha256-DR5tdLgABW/fvMkPzV5tUfWyXe3ie5Pgo1RndFXUxlo=";
  };
  appimage = appimageTools.wrapType2 {
    inherit pname version src;
  };
  appimageContents = appimageTools.extractType2 {
    inherit pname version src;
  };
in

stdenvNoCC.mkDerivation {
  inherit pname version;

  src = appimage;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r bin $out/bin

    mkdir -p $out/share/${pname}
    cp -a ${appimageContents}/locales $out/share/${pname}
    cp -a ${appimageContents}/resources $out/share/${pname}
    cp -a ${appimageContents}/usr/share/icons $out/share
    install -Dm 644 ${appimageContents}/unofficial-homestuck-collection.desktop -T $out/share/applications/unofficial-homestuck-collection.desktop

    substituteInPlace $out/share/applications/unofficial-homestuck-collection.desktop \
      --replace-fail "AppRun" "${pname}" \
      --replace-fail "Categories=game;" "Categories=Game;"

    runHook postInstall
  '';
}
