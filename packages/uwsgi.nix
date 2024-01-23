{ buildPythonPackage, fetchPypi }:
buildPythonPackage rec {
  pname = "uwsgi";
  version = "2.0.23";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-DK/aDBb5Idt/5Cz6+BsWfPiE7hc1Dvvdh9Hs7OLX3jc=";
  };

  preBuild = ''
    mkdir -p $out/bin
    export UWSGI_BIN_NAME=$out/bin/uwsgi
  '';

  doCheck = false;
}
