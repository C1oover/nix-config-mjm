let
  inputs = import ../npins;
in
{
  pkgs ? import inputs.nixos { config.allowUnfree = true; },
}:
let
  inherit (pkgs) lib;
  vault = pkgs.vault-bin;
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
      homepage = "https://registry.terraform.io/providers/Valodim/desec";
    })
  ]);
  evalHive = import "${inputs.colmena}/src/nix/hive/eval.nix";
  hive = evalHive { rawHive = import ../hive.nix; };
  terraformConfiguration =
    (lib.evalModules {
      modules = [
        {
          _module.args = {
            inherit pkgs;
            inherit (hive) nodes;
          };
        }
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
        inherit inputs;
      };
    }).config.terraformConfig.json;

  tofu-scripts = pkgs.callPackage ./scripts { inherit vault opentofu terraformConfiguration; };
in
{
  inherit opentofu terraformConfiguration tofu-scripts;
}
