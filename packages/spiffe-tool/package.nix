{ gitignore, buildGoModule }:

buildGoModule {
  pname = "spiffe-tool";
  version = "0.1.0";

  src = gitignore.gitignoreSource ./.;

  vendorHash = "sha256-5VPLfrR2DwYu7aHtbffenqMHvJa5LC+SZ5r20m7vwX0=";
}
