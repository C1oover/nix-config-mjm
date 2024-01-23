{
  buildPythonPackage,
  fetchPypi,
  click,
}:
buildPythonPackage rec {
  pname = "confusable_homoglyphs";
  version = "3.2.0";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-O0oNn6UQZpSYggyRoL/AwydWjOzskGSM84GdSm/Gp1E=";
  };

  checkInputs = [ click ];
}
