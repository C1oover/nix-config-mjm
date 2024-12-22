{
  stdenv,
  fetchFromGitHub,
  runCommand,
}:

let
  devDir = "/Applications/Xcode.app/Contents/Developer";

  version = "1.0.3-unstable-2023-08-02";
  src = fetchFromGitHub {
    owner = "beeper";
    repo = "barcelona";
    rev = "9a60a4f1b7e341c1e1a6402ca058962c979d8da9";
    hash = "sha256-oNi6K1a80xkg1w3QSf3kAMRyGwX3FyC0Q1Ioi+XfZHw=";
  };

  # This doesn't work yet, because it's trying to write to ~/Library/Caches and that
  # doesn't exist and isn't writable for the nixbld user. Setting $HOME doesn't help.
  # Maybe I can figure out a way to override it at some point.
  packageDeps = stdenv.mkDerivation {
    name = "barcelona-mautrix-deps";
    inherit version src;

    configurePhase = ''
      vendor/bin/xcodegen generate
      export DEVELOPER_DIR=${devDir}
      export HOME=$(mktemp -d)
    '';

    buildPhase = ''
      mkdir -p $out
      /usr/bin/xcodebuild -scheme barcelona-mautrix -resolvePackageDependencies -derivedDataPath "$(mktemp -d)" -clonedSourcePackagesDirPath $out
    '';

    sandboxProfile = ''
      (allow file-read* file-write* process-exec mach-lookup)
      ; block homebrew dependencies
      (deny file-read* file-write* process-exec mach-lookup (subpath "/usr/local") (with no-log))
    '';
  };

  # Building requires a few system tools to be in PATH.
  # Some of these we could patch into the relevant source files (such as xcodebuild and
  # qlmanage) but some are used by Xcode itself and we have no choice but to put them in PATH.
  # Symlinking them in this way is better than just putting all of /usr/bin in there.
  buildSymlinks = runCommand "barcelona-build-symlinks" { } ''
    mkdir -p $out/bin
    ln -s /usr/bin/xcrun /usr/bin/xcodebuild $out/bin
  '';
in

stdenv.mkDerivation {
  name = "barcelona-mautrix";
  inherit version src;

  nativeBuildInputs = [ buildSymlinks ];

  preConfigure = ''
    vendor/bin/xcodegen generate
    export DEVELOPER_DIR=${devDir}
  '';

  buildPhase = ''
    runHook preBuild

    xcodebuild \
      -project \
      barcelona.xcodeproj \
      -scheme \
      barcelona-mautrix \
      -configuration \
      Release \
      -derivedDataPath \
      $NIX_BUILD_TOP/derivedData \
      -clonedSourcePackagesDirPath \
      ${packageDeps}

    runHook postBuild
  '';

  sandboxProfile = ''
    (allow file-read* file-write* process-exec mach-lookup)
    ; block homebrew dependencies
    (deny file-read* file-write* process-exec mach-lookup (subpath "/usr/local") (with no-log))
  '';
}
