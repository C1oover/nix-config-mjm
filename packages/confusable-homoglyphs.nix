{
  buildPythonPackage,
  fetchPypi,
# click,
}:
buildPythonPackage rec {
  pname = "confusable_homoglyphs";
  version = "3.3.1";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-uZUAHJsuG0zqDPXzhAp8eRiKjLutBT1pNXK9jBwexGA=";
  };

  # checkInputs = [ click ];
  doCheck = false;
}
