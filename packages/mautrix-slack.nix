{
  lib,
  buildGoModule,
  fetchFromGitHub,
  olm,
}:

buildGoModule rec {
  name = "mautrix-slack";
  version = "0.1.1";

  src = fetchFromGitHub {
    owner = "mautrix";
    repo = "slack";
    rev = "v${version}";
    hash = "sha256-RCqCKu69wtgr8mCWbRWYhH9ZmiBC04kNPsfGxBS+E9w=";
  };

  buildInputs = [ olm ];

  vendorHash = "sha256-JUqSVFuCIlcjmvgho0lr2OWPM4gWN8rAukOcg9kKMlE=";

  meta = with lib; {
    description = " A Matrix-Slack puppeting bridge";
    homepage = "https://github.com/mautrix/slack";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ mjm ];
  };
}
