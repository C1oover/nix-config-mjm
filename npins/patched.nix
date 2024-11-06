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
  # bcachefs-fstab-generator
  desktops."345207".hash = "sha256-fSuTIECQKnQ0ntgcIm9zRD64EvhcU+8bLJ8kOlh7QsQ=";
  # fix less
  desktops."352298".hash = "sha256-skk+ldAKK+zthgNpXNj6eF59P1uzsFPqKaSNIIxZIlg=";
  # fix vte build on darwin
  darwin."353204".hash = "sha256-dAOW9qErQE0yLhoL9iifhXv8v4v4UWs6FnF9R8Ap4ZY=";
}
