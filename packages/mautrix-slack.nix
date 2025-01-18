{
  lib,
  buildGoModule,
  fetchFromGitHub,
  olm,
}:

buildGoModule rec {
  name = "mautrix-slack";
  version = "0.1.4";

  src = fetchFromGitHub {
    owner = "mautrix";
    repo = "slack";
    rev = "v${version}";
    hash = "sha256-MDbWvbEY8+CrUL1SnjdJ4SqyOH/5gPsEQkLnTHyJdOo=";
  };

  buildInputs = [ olm ];

  vendorHash = "sha256-8U6ifMLRF7PJyG3hWKgBtj/noO/eCXXD60aeB4p2W54=";

  meta = with lib; {
    description = " A Matrix-Slack puppeting bridge";
    homepage = "https://github.com/mautrix/slack";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ mjm ];
  };
}
