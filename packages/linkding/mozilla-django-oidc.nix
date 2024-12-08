{
  buildPythonPackage,
  fetchPypi,
  cryptography,
  requests,
  josepy,
}:

buildPythonPackage rec {
  pname = "mozilla-django-oidc";
  version = "4.0.1";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-T/jGQGnj4FxTnOz5NF5zIlqZZBol4Tt6X5M+yJe1iRg=";
  };

  propagatedBuildInputs = [
    cryptography
    requests
    josepy
  ];

  dontUseSetuptoolsCheck = true;
}
