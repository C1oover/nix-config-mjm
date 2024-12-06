{
  lib,
  beam,
  nix-eval-jobs,
  nix-output-monitor,
  makeWrapper,
  nix-gitignore,
  nvd-json,
  attic-client,
}:

let
  beamPackages = beam.packages.erlang_27;
in

beamPackages.mixRelease rec {
  pname = "nixos-deploy";
  version = "0.1.0";

  src = nix-gitignore.gitignoreSource ''
    /.*
    /README.md
    /*.nix
  '' ./.;

  mixFodDeps = beamPackages.fetchMixDeps {
    inherit version src;
    pname = "nixos-deploy-deps";
    hash = "sha256-BEWkuXh1fTrCBBTCFBloSHHA83YtHF2znOaLIdL14Xk=";
  };

  nativeBuildInputs = [ makeWrapper ];

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
