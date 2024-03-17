{
  lib,
  buildGoModule,
  fetchFromGitHub,
  olm,
}:

buildGoModule {
  name = "mautrix-slack";
  version = "0-unstable-2024-02-15";

  src = fetchFromGitHub {
    owner = "mautrix";
    repo = "slack";
    rev = "a9ba2f9249bdc5df69a1349122d1769e7e48c9e1";
    hash = "sha256-NE/YsiYm6t/6LNilATIvk0CcOFiQAqgw533WyhMZgvQ=";
  };

  buildInputs = [ olm ];

  vendorHash = "sha256-FL0wObZIvGV9V7pLmrxTILQ/TGEMSH8/2wFPlu6idcA=";

  meta = with lib; {
    description = " A Matrix-Slack puppeting bridge";
    homepage = "https://github.com/mautrix/slack";
    license = licenses.agpl3;
    maintainers = with maintainers; [ mjm ];
  };
}
