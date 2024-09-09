let
  sources = import ../../npins;
in
{
  pkgs ? import sources.nixos { },
}:

pkgs.mkShell {
  packages = builtins.attrValues {
    inherit (pkgs)
      cargo
      cargo-watch
      rustc
      rust-analyzer
      rustfmt

      openssl
      pkg-config
      ;
  };

  shellHook = ''
    export LAUNCHPAD_PAPERLESS_TOKEN_FILE=".secrets/paperless_token"
    export LAUNCHPAD_GITLAB_TOKEN_FILE=".secrets/gitlab_token"
  '';
}
