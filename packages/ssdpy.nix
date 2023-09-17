{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools-scm,
}:
buildPythonPackage rec {
  pname = "ssdpy";
  version = "0.4.1";
  format = "pyproject";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-SXHGoBD3fxR+zb7JWT8tkYfD+2Nliw9ewI9Me+I4dCU=";
  };

  nativeBuildInputs = [setuptools-scm];

  meta = with lib; {
    license = licenses.mit;
  };
}
