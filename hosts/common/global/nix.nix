{ inputs, pkgs, ... }:
let
  lix-module = import "${inputs.lix-module}/module.nix" { inherit (inputs) lix; };
in
{

  imports = [ lix-module ];

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    substituters = [
      "https://nix-community.cachix.org"
      "https://devenv.cachix.org"
      "https://helix.cachix.org"
      # "https://0uptime.cachix.org"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
      # "0uptime.cachix.org-1:ctw8yknBLg9cZBdqss+5krAem0sHYdISkw/IFdRbYdE="
    ];
  };

  nixpkgs = {
    config.allowUnfree = true;
    overlays = [
      (final: prev: {
        nur = import inputs.nur {
          nurpkgs = prev;
          pkgs = prev;
        };
      })
    ];
  };

  nix.nixPath = [ "nixpkgs=${pkgs.path}" ];
  nix.registry.nixpkgs.flake.outPath = pkgs.path;

  programs.nix-index.enable = true;
}
