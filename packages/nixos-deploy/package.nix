{
  lib,
  stdenv,
  fetchFromGitHub,
  beam,
  nix-eval-jobs,
  nix-output-monitor,
  makeWrapper,
  nix-gitignore,
  nvd-json,
  attic-client,
  rustPlatform,
}:

let
  beamPackages = beam.packages.erlang_27;

  version = "0.1.0";
  src = nix-gitignore.gitignoreSource ''
    /.*
    /README.md
    /*.nix
  '' ./.;

  ramboShim = stdenv.mkDerivation (finalAttrs: {
    name = "rambo-shim";
    version = "0.3.4";

    src = fetchFromGitHub {
      owner = "jayjun";
      repo = "rambo";
      tag = finalAttrs.version;
      hash = "sha256-L3yM3KCbYWw4HPmP7WLQoQlHwuvLWEUyHwy+/MR2Z7w=";
    };

    sourceRoot = "${finalAttrs.src.name}/priv";

    cargoDeps = rustPlatform.fetchCargoTarball {
      inherit (finalAttrs) src sourceRoot;
      hash = "sha256-nqfNpS+phDk0B8Padfo30xJmFx5yzS24osv6VHBF23o=";
    };

    nativeBuildInputs = with rustPlatform; [
      cargoSetupHook
      cargoBuildHook
      cargoInstallHook
    ];

    cargoBuildType = "release";
  });

  mixFodDeps = beamPackages.fetchMixDeps {
    inherit version src;
    pname = "nixos-deploy-deps";
    hash = "sha256-3dKULPoXslMeq7tm58TaoUpOKufSrCYtMujjyu+Q1lA=";
  };
in

beamPackages.mixRelease {
  pname = "nixos-deploy";
  inherit version src mixFodDeps;

  nativeBuildInputs = [ makeWrapper ];

  postUnpack = ''
    substituteInPlace $MIX_DEPS_PATH/rambo/lib/mix/tasks/compile.rambo.ex \
      --replace-fail 'Path.join(:code.priv_dir(:rambo), @filename)' "\"${ramboShim}/bin/rambo\""
  '';

  postBuild = ''
    mix escript.build
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp -v nixos_deploy $out/bin/nixos-deploy

    wrapProgram $out/bin/nixos-deploy \
      --prefix PATH : ${
        lib.makeBinPath [
          beamPackages.elixir_1_17
          beamPackages.erlang
          nix-eval-jobs
          nix-output-monitor
          nvd-json
          attic-client
        ]
      }

    runHook postInstall
  '';

  meta = {
    mainProgram = "nixos-deploy";
  };
}
