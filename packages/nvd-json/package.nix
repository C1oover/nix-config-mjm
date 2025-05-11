{
  gitignore,
  rustPlatform,
}:
rustPlatform.buildRustPackage {
  pname = "nvd-json";
  version = "0.1.0";

  src = gitignore.gitignoreSource ./.;

  cargoLock.lockFile = ./Cargo.lock;
}
