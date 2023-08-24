{
  appimageTools,
  lib,
  fetchurl,
  makeWrapper,
  writeShellScript,
  curl,
  gnugrep,
  pcre,
  common-updater-scripts,
}:
appimageTools.wrapType2 rec {
  pname = "beeper";
  version = "3.71.16";

  src = fetchurl {
    url = "https://download.beeper.com/linux/appImage/x64";
    sha256 = "Ho5zFmhNzkOmzo/btV+qZfP2GGx5XvV/1JncEKlH4vc=";
  };

  extraInstallCommands = ''
    source ${makeWrapper}/nix-support/setup-hook
    mv $out/bin/${pname}-${version} $out/bin/${pname}
    wrapProgram $out/bin/${pname} \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform=wayland}}"
  '';

  passthru = {
    updateScript = writeShellScript "update-beeper" ''
      set -o errexit
      export PATH="${lib.makeBinPath [curl gnugrep pcre common-updater-scripts]}"
      version="$(curl -sI -X GET https://download.beeper.com/linux/appImage/x64 | grep -Fi 'content-disposition:' | pcregrep -o1 '(([0-9]\.?)+[0-9])')"
      update-source-version beeper "$version"
    '';
  };

  meta = with lib; {
    description = "All your chats in one app.";
    homepage = "https://beeper.com";
    license = licenses.unfree;
    maintainers = [];
    platforms = ["x86_64-linux"];
  };
}
