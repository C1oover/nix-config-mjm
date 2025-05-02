{ lib, buildGoModule }:

buildGoModule {
  pname = "spire-secrets";
  version = "0.1.0";

  src = lib.cleanSource ./.;

  vendorHash = "sha256-fMNN58MQ1G9bRocZuMEk1tKGDVDdk6dMwjXKc0uxB8E=";

  meta.mainProgram = "spire-secrets";
}
