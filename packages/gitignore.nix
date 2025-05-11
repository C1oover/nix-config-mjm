{ lib }:

let
  sources = import ../npins;
  gitignore = import sources.gitignore { inherit lib; };
in
gitignore
