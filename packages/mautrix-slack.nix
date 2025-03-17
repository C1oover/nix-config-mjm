{
  lib,
  buildGoModule,
  fetchFromGitHub,
  olm,
}:

buildGoModule rec {
  pname = "mautrix-slack";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "mautrix";
    repo = "slack";
    rev = "v${version}";
    hash = "sha256-y6DsojQQAQkAB4puhk3DLheVvjn0puoYvzoX1H7gBEM=";
  };

  buildInputs = [ olm ];

  vendorHash = "sha256-1aYg6wDG2hzUshtHs9KiJDAFb4OM1oupUJAh3LR4KxY=";

  meta = with lib; {
    description = " A Matrix-Slack puppeting bridge";
    homepage = "https://github.com/mautrix/slack";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ mjm ];
  };
}
