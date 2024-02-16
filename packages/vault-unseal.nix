{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "vault-unseal";
  version = "0.5.1";

  src = fetchFromGitHub {
    owner = "lrstanley";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-vjU4080uCId/73F7CJKDtk9b1siCPIZOaSczKMNf0LE=";
  };

  vendorHash = "sha256-SEA74Tk0R3BHyLMZEgKatfLGbX7l8Zyn/JkQVfEckI4=";

  meta = with lib; {
    description = "Auto-unseal utility for Hashicorp Vault";
    homepage = "https://github.com/lrstanley/vault-unseal";
    license = licenses.mit;
    mainProgram = "vault-unseal";
  };
}
