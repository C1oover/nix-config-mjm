let
  inputs = import ./.;
  lib = import "${inputs.nixos}/lib";

  pkgsForPatching = import inputs.nixos { };
  inherit (pkgsForPatching) applyPatches fetchpatch;

  nameToKind = {
    nixpkgs = "darwin";
    nixos = "desktops";
    nixos-small = "servers";
  };

  overlayPatches =
    patches:
    lib.mapAttrs (
      name: src:
      if lib.hasAttr name nameToKind then
        patchNixpkgs {
          inherit src patches;
          kind = nameToKind.${name};
        }
      else
        src
    ) inputs;

  mkPatches =
    patches: kind:
    lib.mapAttrsToList (
      name: value: fetchpatch ({ url = "https://github.com/NixOS/nixpkgs/pull/${name}.diff"; } // value)
    ) (patches.${kind} or { });

  patchNixpkgs =
    {
      src,
      kind,
      patches,
    }:
    let
      mkPatches' = mkPatches patches;
      allPatches = mkPatches' "global" ++ mkPatches' kind;
    in
    if allPatches == [ ] then
      src
    else
      applyPatches {
        name = "${src.name}-patched";
        patches = allPatches;
        inherit src;
      };
in
overlayPatches {
  # invidious update to fix subscriptions/channels
  servers."355279".hash = "sha256-uN4FXoe7d6WU6habECrYlAi+NqweFNsiB6xkBPn0HGM=";

  # zellij 0.41.1
  darwin."353630".hash = "sha256-AAmWSZU5nMriyndtPs9xugJE7nVn0DlYdfdtvsqL9o8=";

  # bcachefs-fstab-generator
  desktops."345207".hash = "sha256-fSuTIECQKnQ0ntgcIm9zRD64EvhcU+8bLJ8kOlh7QsQ=";

  # fix less
  desktops."352298".hash = "sha256-skk+ldAKK+zthgNpXNj6eF59P1uzsFPqKaSNIIxZIlg=";
}
