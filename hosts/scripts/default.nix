{
  lib,
  stdenvNoCC,
  nushell,
  makeWrapper,
  coreutils,
  openssh,
  vault,
  attic-client,
  colmena,
  nix-output-monitor,
  nvd,
  nettools,
  nix,
  systemd,
}:
let
  scripts = [
    "ci-attic-login"
    "deploy"
    "ci-deploy"
    "ci-build"
  ];
  variantScripts = [
    "rebuild"
    "switch"
  ];
  allScripts = scripts ++ variantScripts;
  variant = if stdenvNoCC.isLinux then "linux" else "darwin";

  installScript = name: src: ''
    install -Dv ${src} $out/bin/${name}
    sed -i "1c\\#!${nushell}/bin/nu --env-config /dev/null -I $out/libexec/nu" $out/bin/${name}

    wrapProgram $out/bin/${name} \
      --prefix PATH : ${
        lib.makeBinPath (
          [
            coreutils
            openssh
            vault
            attic-client
            colmena
            nix-output-monitor
            nvd
            nix
          ]
          ++ lib.optionals stdenvNoCC.isLinux [
            nettools
            systemd
          ]
        )
      }
  '';
in
stdenvNoCC.mkDerivation {
  pname = "host-scripts";
  version = "0.0.1";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    install -Dv helpers.nu $out/libexec/nu/helpers.nu

    ${lib.concatMapStrings (script: installScript script "${script}.nu") scripts}
    ${lib.concatMapStrings (script: installScript script "${script}.${variant}.nu") variantScripts}
  '';

  passthru.scripts = allScripts;
}
