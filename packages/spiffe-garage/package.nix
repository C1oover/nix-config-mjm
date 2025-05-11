{ gitignore, buildGoModule }:

buildGoModule {
  pname = "spiffe-garage";
  version = "0.1.0";

  src = gitignore.gitignoreSource ./.;

  vendorHash = "sha256-//8/65ne4juNnMWfetCMpMEJqukPk2aQnYXTa2zPPps=";
}
