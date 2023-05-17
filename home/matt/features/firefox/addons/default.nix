{
  fetchurl,
  lib,
  stdenv,
} @ args: let
  buildFirefoxXpiAddon = lib.makeOverridable ({
    stdenv ? args.stdenv,
    fetchurl ? args.fetchurl,
    pname,
    version,
    addonId,
    url,
    sha256,
    meta,
    ...
  }:
    stdenv.mkDerivation {
      name = "${pname}-${version}";

      inherit meta;

      src = fetchurl {inherit url sha256;};

      preferLocalBuild = true;
      allowSubstitutes = true;

      buildCommand = ''
        dst="$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
        mkdir -p "$dst"
        install -v -m644 "$src" "$dst/${addonId}.xpi"
      '';
    });

  packages = import ./addons.nix {
    inherit buildFirefoxXpiAddon fetchurl lib stdenv;
  };
in
  packages
  // {
    inherit buildFirefoxXpiAddon;

    catppuccin-latte-mauve = buildFirefoxXpiAddon {
      pname = "catppuccin-latte-mauve";
      version = "2.0";
      addonId = "{c827c446-3d00-4160-a992-3ebcbe6d81a6}";
      url = "https://github.com/catppuccin/firefox/releases/download/old/catppuccin_latte_mauve.xpi";
      sha256 = "sha256-/3O1AoED5/kYXM86fNVLY9D+FdMGe3el4gdigseIIxM=";
      meta = with lib; {
        homepage = "https://github.com/catppuccin/firefox";
        description = "Soothing pastel theme for Firefox";
        license = licenses.mit;
        platforms = platforms.all;
      };
    };
  }
