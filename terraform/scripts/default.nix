{
  lib,
  bash,
  resholve,
  coreutils,
  vault,
  opentofu,
  terraformConfiguration,
}:
let
  scripts = [
    "tf-plan"
    "tf-apply"
    "ci-terraform-plan"
    "ci-terraform-apply"
  ];
in
resholve.mkDerivation {
  pname = "tofu-scripts";
  version = "0.0.1";

  src = ./.;

  installPhase = ''
    sed -i '1i TF_CONFIG="${terraformConfiguration}"' functions.sh
    install -Dv functions.sh $out/functions.sh
    ${lib.concatMapStrings (script: ''
      install -Dv ${script}.sh $out/bin/${script}
    '') scripts}
  '';

  passthru.scripts = scripts;

  solutions.default = {
    scripts = [ "functions.sh" ] ++ (map (script: "bin/${script}") scripts);
    interpreter = "${bash}/bin/bash";
    inputs = [
      coreutils
      vault
      opentofu
    ];
    execer = [
      "cannot:${vault}/bin/vault"
      "cannot:${opentofu}/bin/tofu"
    ];
  };
}
