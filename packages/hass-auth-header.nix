{
  lib,
  buildHomeAssistantComponent,
  fetchFromGitHub,
# isort,
# black,
# ruff,
# pylint,
}:
buildHomeAssistantComponent rec {
  owner = "BeryJu";
  domain = "auth_header";
  version = "unstable-2023-12-25";

  src = fetchFromGitHub {
    inherit owner;
    repo = "hass-auth-header";
    rev = "50fe1988253e2929f1492c1c762a8b6620dad8d8";
    hash = "sha256-k1f9y/7L3ttreKbERZIollwkRyCwdr2Rt7lnVQWFa80=";
  };

  #nativeBuildInputs = [black isort ruff pylint];
  dontBuild = true;

  meta = with lib; {
    description = "Home Assistant custom component which allows you to delegate authentication to a reverse proxy";
    homepage = "https://github.com/BeryJu/hass-auth-header";
    maintainers = with maintainers; [ mjm ];
    license = licenses.gpl3;
  };
}
