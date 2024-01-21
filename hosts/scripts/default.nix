{
  lib,
  bash,
  resholve,
  coreutils,
  openssh,
  vault,
  attic,
  colmena,
}: let
  scripts = [
    "unseal"
    "ci-attic-login"
    "deploy"
    "ci-deploy"
  ];
in
  resholve.mkDerivation {
    pname = "host-scripts";
    version = "0.0.1";

    src = ./.;

    installPhase = ''
      sed -i '9i ATTIC="${attic}"' ci-attic-login.sh
      install -Dv functions.sh $out/functions.sh
      ${lib.concatMapStrings (script: ''
          install -Dv ${script}.sh $out/bin/${script}
        '')
        scripts}
    '';

    passthru.scripts = scripts;

    solutions.default = {
      scripts = ["functions.sh"] ++ (map (script: "bin/${script}") scripts);
      interpreter = "${bash}/bin/bash";
      inputs = [
        coreutils
        openssh
        vault
        attic
        colmena
      ];
      fake.external = ["op"];
      execer = [
        "cannot:${vault}/bin/vault"
        "cannot:${openssh}/bin/ssh-keygen"
        "cannot:${colmena}/bin/colmena"
      ];
    };
  }
