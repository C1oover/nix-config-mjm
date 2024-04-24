{
  lib,
  stdenv,
  bash,
  resholve,
  coreutils,
  openssh,
  vault,
  attic-client,
  colmena,
  rbw,
  nix-output-monitor,
  nvd,
  nettools,
  nix,
  systemd,
}:
let
  scripts = [
    "unseal"
    "ci-attic-login"
    "deploy"
    "ci-deploy"
  ];
  allScripts = scripts ++ [
    "rebuild"
    "switch"
  ];
  variant = if stdenv.isLinux then "linux" else "darwin";
in
resholve.mkDerivation {
  pname = "host-scripts";
  version = "0.0.1";

  src = ./.;

  installPhase = ''
    install -Dv functions.sh $out/functions.sh
    ${lib.concatMapStrings (script: ''
      install -Dv ${script}.sh $out/bin/${script}
    '') scripts}
    ${lib.concatMapStrings
      (script: ''
        install -Dv ${script}.${variant}.sh $out/bin/${script}
      '')
      [
        "rebuild"
        "switch"
      ]
    }
  '';

  passthru.scripts = allScripts;

  solutions.default = {
    scripts = [ "functions.sh" ] ++ (map (script: "bin/${script}") allScripts);
    interpreter = "${bash}/bin/bash";
    inputs =
      [
        coreutils
        openssh
        vault
        attic-client
        colmena
        rbw
        nix-output-monitor
        nvd
        nix
      ]
      ++ lib.optionals stdenv.isLinux [
        nettools
        systemd
      ];
    fake.external = [
      "sudo"
      "scutil"
    ];
    keep."$PWD" = true;
    execer = [
      "cannot:${vault}/bin/vault"
      "cannot:${openssh}/bin/ssh-keygen"
      "cannot:${colmena}/bin/colmena"
      "cannot:${rbw}/bin/rbw"
      "cannot:${nix-output-monitor}/bin/nom"
      "cannot:${nix-output-monitor}/bin/nom-build"
      "cannot:${nvd}/bin/nvd"
    ];
  };
}
