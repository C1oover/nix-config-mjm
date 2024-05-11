{
  lib,
  stdenvNoCC,
  makeWrapper,
  nushell,
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
stdenvNoCC.mkDerivation {
  pname = "tofu-scripts";
  version = "0.0.1";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = [ nushell ];

  installPhase = ''
    install -Dv helpers.nu $out/libexec/nu/helpers.nu

    ${lib.concatMapStrings (script: ''
      install -Dv ${script}.nu $out/bin/${script}
      sed -i "1c\\#!${nushell}/bin/nu --env-config \'\' -I $out/libexec/nu" $out/bin/${script}

      wrapProgram $out/bin/${script} \
        --set TF_CONFIG ${terraformConfiguration} \
        --prefix PATH : ${
          lib.makeBinPath [
            coreutils
            opentofu
            vault
          ]
        }
    '') scripts}
  '';

  passthru.scripts = scripts;
}
