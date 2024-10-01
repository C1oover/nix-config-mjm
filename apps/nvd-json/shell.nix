let
  sources = import ../../npins;
in
{
  pkgs ? import sources.nixos-small { },
}:

# let
#   pkg = import ./default.nix { inherit pkgs; };
# in

pkgs.mkShell {
  # inputsFrom = [ pkg ];
  packages = builtins.attrValues {
    inherit (pkgs)
      cargo
      rustc
      rust-analyzer
      rustfmt

      just
      ;
  };
}
