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
  scripts = [ "host-scripts" ];
  variantScripts = [
    "rebuild"
    "switch"
  ];
  allScripts = scripts ++ variantScripts;
  variant = if stdenvNoCC.isLinux then "linux" else "darwin";

  installScript = name: src: ''
    install -Dv ${src} $out/bin/${name}

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

  buildInputs = [ nushell ];

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    ${installScript "host-scripts" "host-scripts.nu"}
    ${lib.concatMapStrings (script: installScript script "${script}.${variant}.nu") variantScripts}
  '';

  passthru.scripts = allScripts;

  meta.mainProgram = "host-scripts";
}
