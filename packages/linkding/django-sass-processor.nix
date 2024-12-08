{
  buildPythonPackage,
  fetchPypi,
  libsass,
  django,
  django-compressor,
}:
buildPythonPackage rec {
  pname = "django-sass-processor";
  version = "1.4";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-sX850H06dRCuxCXBkZN+IwUC3ut8pr9pUKGt+LS3wcM=";
  };

  propagatedBuildInputs = [
    django
    django-compressor
    libsass
  ];

  dontUseSetuptoolsCheck = true;
  pythonImportsCheck = [ "sass_processor" ];
}
