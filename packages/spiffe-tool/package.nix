{ gitignore, buildGoModule }:

buildGoModule {
  pname = "spiffe-tool";
  version = "0.1.0";

  src = gitignore.gitignoreSource ./.;

  vendorHash = "sha256-cdcJIFoR3AKQOwHnzqha7bA+BVNaQU1kJdLUy7HaFYg=";
}
