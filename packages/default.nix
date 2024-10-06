{
  inputs ? import ../npins,
  pkgs ? import inputs.nixos { config.allowUnfree = true; },
}:
let
  tf = import ../terraform { inherit pkgs; };

  callPackage = pkgs.lib.callPackageWith (pkgs // packages);
  packages = {
    caddy-desec = callPackage ./caddy { };
    cliraop = callPackage ./cliraop.nix { };
    homelab = callPackage ../apps/homelab/package.nix { };
    host-scripts = callPackage ../hosts/scripts { vault = pkgs.vault-bin; };
    linkding = callPackage ./linkding.nix { };
    mautrix-slack = callPackage ./mautrix-slack.nix { };
    nu-lib = callPackage ./nu-lib { };
    nvd-json = callPackage ../apps/nvd-json/package.nix { };
    pragmata-pro = callPackage ./pragmata-pro.nix { };
    scripts = callPackage ../scripts { };
    tofu-scripts = callPackage ../terraform/scripts {
      vault = pkgs.vault-bin;
      inherit (tf) opentofu terraformConfiguration;
    };
    writeNu = callPackage ./nu-lib/writer.nix { };
    writeNuBin = callPackage ({ writeNu }: name: writeNu "/bin/${name}") { };
  };
in
packages
