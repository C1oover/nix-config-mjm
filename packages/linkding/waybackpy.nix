{
  buildPythonPackage,
  fetchPypi,
  click,
  requests,
  urllib3,
  pytest,
}:
buildPythonPackage rec {
  pname = "waybackpy";
  version = "3.0.6";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-SXo3F1arp2ROt62g69TtsVy4xTvBNMyXO/AjoSyv+D8=";
  };

  propagatedBuildInputs = [
    click
    requests
    urllib3
  ];
  nativeCheckInputs = [ pytest ];
}
