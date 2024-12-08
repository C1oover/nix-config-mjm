{
  buildPythonPackage,
  fetchPypi,
  setuptools-scm,
  django,
  confusable-homoglyphs,
}:
buildPythonPackage rec {
  pname = "django-registration";
  version = "3.4";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-GgzO9+9x5np4pVGr2K03iXfcFKA28fzYvkIqaL1SVKk=";
  };

  nativeBuildInputs = [ setuptools-scm ];
  propagatedBuildInputs = [
    django
    confusable-homoglyphs
  ];
}
