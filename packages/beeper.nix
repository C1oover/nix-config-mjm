{
  appimageTools,
  lib,
  fetchurl,
  symlinkJoin,
  makeWrapper,
}: let
  beeper = appimageTools.wrapType2 rec {
    pname = "beeper";
    version = "3.65.19";

    src = fetchurl {
      url = "https://download.beeper.com/linux/appImage/x64";
      sha256 = "1hyrsjrvv985pqii6s11wvdmsdv8iqmz94835ls7rqg8ap96kyrq";
    };

    extraInstallCommands = ''
      mv $out/bin/${pname}-${version} $out/bin/${pname}
    '';

    meta = with lib; {
      description = "All your chats in one app.";
      homepage = "https://beeper.com";
      license = licenses.unfree;
      maintainers = [];
      platforms = ["x86_64-linux"];
    };
  };
in
  symlinkJoin {
    name = "beeper";
    paths = [beeper];
    buildInputs = [makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/beeper \
        --add-flags '--enable-features=UseOzonePlatform --ozone-platform=wayland'
    '';
  }
