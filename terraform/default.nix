{
  sources ? import ../npins/patched.nix,
  pkgs ? import sources.nixos { config.allowUnfree = true; },
}:
let
  inherit (pkgs) lib;
  opentofu = pkgs.opentofu.withPlugins (p: [
    p.vault
    p.proxmox
    (p.mkProvider {
      owner = "Valodim";
      repo = "terraform-provider-desec";
      rev = "v0.5.0";
      spdx = "MIT";
      hash = "sha256-t+hpNI1Id8DrtQWuDj9OSdKkKMo/b1O2ViCSXjDxSlQ=";
      vendorHash = "sha256-Dcs1R3smMIRnjiGpt6ML1lsfYYl4ne8gK+BwDravhVI=";
      homepage = "https://registry.opentofu.org/Valodim/desec";
    })
  ]);
  nodes = import ../plans.nix { tofuNodes = true; };
  terraformConfiguration =
    (lib.evalModules {
      modules = [
        { _module.args = { inherit pkgs nodes; }; }
        {
          terraform.terraform.backend.consul = {
            scheme = "http";
            access_token = "";
            datacenter = "dc1";
            path = "terraform/state";
          };
        }
        ./vault.nix
        ./terraform.nix
      ];
      specialArgs = {
        inputs = sources;
      };
    }).config.terraformConfig.json;
in
{
  inherit opentofu terraformConfiguration;
}
