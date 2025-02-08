{ oldpkgs, rustPlatform }:

let
  prev = oldpkgs.bcachefs-fstab-generator;
in

prev.overrideAttrs {
  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit (prev) src name;
    hash = "sha256-W9p8EEluU0+BSz3zR1LuQ6IgVYaZtuaIfpM4BDRH0WM=";
  };
}
