{
  stdenvNoCC,
  appimageTools,
  fetchurl,
}:

let
  pname = "wago";
  version = "2.5.7";
  src = fetchurl {
    url = "https://wago-addons.ams3.digitaloceanspaces.com/app_latest/WagoApp_Setup.AppImage";
    hash = "sha256-KlfQoLTpcq0rT296PMKaY9nma/Jbu8l7bR0H8K6WLNo=";
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
    install -Dm 644 ${appimageContents}/WagoApp.desktop -T $out/share/applications/wago.desktop

    substituteInPlace $out/share/applications/wago.desktop --replace "AppRun" "${pname}"

    runHook postInstall
  '';
}
