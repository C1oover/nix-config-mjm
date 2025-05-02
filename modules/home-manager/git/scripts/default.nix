{
  lib,
  bash,
  resholve,
  coreutils,
  jujutsu,
  fzf,
}:
let
  scripts = [
    "jf"
    "jco"
  ];
in
resholve.mkDerivation {
  pname = "git-scripts";
  version = "0.0.1";

  src = lib.cleanSource ./.;

  installPhase = ''
    ${lib.concatMapStrings (script: ''
      install -Dv ${script}.sh $out/bin/,${script}
    '') scripts}
  '';

  passthru.scripts = scripts;

  solutions.default = {
    scripts = map (script: "bin/,${script}") scripts;
    interpreter = "${bash}/bin/bash";
    inputs = [
      coreutils
      jujutsu
      fzf
      "${placeholder "out"}/bin"
    ];
    execer = [
      "cannot:${placeholder "out"}/bin/,jf"
      "cannot:${jujutsu}/bin/jj"
      "cannot:${fzf}/bin/fzf"
    ];
  };
}
