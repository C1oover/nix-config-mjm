{
  bash,
  resholve,
  curl,
  jq,
  npins,
  git,
}:
resholve.mkDerivation {
  pname = "scripts";
  version = "0.0.1";

  src = ./.;

  installPhase = ''
    install -Dv ci-update-pins.sh $out/bin/ci-update-pins
  '';

  solutions.default = {
    scripts = [ "bin/ci-update-pins" ];
    interpreter = "${bash}/bin/bash";
    inputs = [
      curl
      jq
      npins
      git
    ];
    execer = [
      "cannot:${npins}/bin/npins"
      "cannot:${git}/bin/git"
    ];
  };
}
