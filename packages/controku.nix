{
  lib,
  python3Packages,
  fetchFromGitHub,
  setuptools-scm,
  requests,
  ssdpy,
  appdirs,
  pygobject3,
  gtk3,
  gobject-introspection,
  wrapGAppsHook,
}:
python3Packages.buildPythonApplication rec {
  pname = "controku";
  version = "1.1.0";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "benthetechguy";
    repo = "controku";
    rev = version;
    hash = "sha256-sye2GtL3a77pygllZc6ylaIP7faPb+NFbyKKyqJzIXw=";
  };

  nativeBuildInputs = [setuptools-scm wrapGAppsHook gobject-introspection];

  propagatedBuildInputs = [requests ssdpy gtk3 appdirs pygobject3];

  meta = with lib; {
    changelog = "https://github.com/benthetechguy/controku/releases/tag/${version}";
    description = "Control Roku devices from the comfort of your own desktop";
    homepage = "https://github.com/benthetechguy/controku";
    license = licenses.gpl3Only;
  };
}
