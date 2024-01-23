{
  buildPythonPackage,
  fetchPypi,
  click,
  django,
  six,
}:
buildPythonPackage rec {
  pname = "django_generate_secret_key";
  version = "1.0.2";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-4v6bV87YLpocrYRRKZxNrPCXFY5ghD7zWm0TaD858Zc=";
  };

  propagatedBuildInputs = [ django ];
  doCheck = false;
}
