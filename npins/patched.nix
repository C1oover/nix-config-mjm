let
  inputs = import ./.;
  lib = import "${inputs.nixos}/lib";

  pkgsForPatching = import inputs.nixos { };
  inherit (pkgsForPatching) applyPatches fetchpatch2;

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
      name: value:
      fetchpatch2 (
        {
          name = "nixpkgs-pr-${name}";
          url = "https://github.com/NixOS/nixpkgs/pull/${name}.diff?full_index=1";
        }
        // value
      )
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
  # opentofu: fix mkProvider
  servers."360647".hash = "sha256-OIbrP0WybgD+JWsnaUq953zo7iKxJzvkOBlL83bhFcQ=";
  desktops."360647".hash = "sha256-OIbrP0WybgD+JWsnaUq953zo7iKxJzvkOBlL83bhFcQ=";

  # bcachefs-fstab-generator
  desktops."345207".hash = "sha256-tI+wlhyC2e63NirN2kgg1I4GMPvMwFTIFFyo2nR1MDQ=";
}
