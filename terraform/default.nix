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
    p.cloudflare
    p.proxmox
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
