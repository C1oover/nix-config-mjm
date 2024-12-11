patches:

let
  sources = import ../npins;
  lib = import (sources.nixos + "/lib");

  inherit (import sources.nixos { }) applyPatches fetchpatch2;

  # TODO better name than global?
  globalNixpkgsPatches = mkPatches "global" nixpkgsRepo;

  mkPatches =
    srcName: repo:
    lib.mapAttrsToList (
      name: value:
      mkPatch (
        {
          id = name;
          inherit repo;
        }
        // value
      )
    ) (patches.${srcName} or { });

  mkPatch =
    {
      id,
      hash ? "",
      repo,
    }:
    fetchpatch2 {
      name = "${repo.repo}-pr-${id}";
      url = "https://github.com/${repo.owner}/${repo.repo}/pull/${id}.diff?full_index=1";
      inherit hash;
    };

  patchSource =
    name: source:
    let
      sourcePatches = getSourcePatches name source;
    in
    if sourcePatches == [ ] then
      source
    else
      applyPatches {
        name = "${name}-patched";
        patches = sourcePatches;
        src = source;
      };

  getSourcePatches =
    name: source:
    let
      repo = getSourceRepo source;
      sourcePatches = mkPatches name repo;
    in
    if source.type == "Channel" then globalNixpkgsPatches ++ sourcePatches else sourcePatches;

  getSourceRepo = source: source.repository or nixpkgsRepo;

  # Repo info for nixpkgs channel sources, which don't have a repository attribute
  nixpkgsRepo = {
    owner = "NixOS";
    repo = "nixpkgs";
    type = "GitHub";
  };
in
lib.mapAttrs patchSource sources
