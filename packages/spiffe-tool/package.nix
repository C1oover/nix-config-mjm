{ gitignore, buildGoModule }:

buildGoModule {
  pname = "spiffe-tool";
  version = "0.1.0";

  src = gitignore.gitignoreSource ./.;

  vendorHash = "sha256-SA+LyvCz9Mp5hYdrUYXmUAiXOm7yS7QktBFhkssNwIc=";
}
