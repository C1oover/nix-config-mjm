{
  lib,
  rustPlatform,
}:
rustPlatform.buildRustPackage {
  pname = "nvd-json";
  version = "0.1.0";

  src = lib.cleanSource ./.;

  cargoLock.lockFile = ./Cargo.lock;
}
