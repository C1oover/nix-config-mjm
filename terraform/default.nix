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
  terraformConfiguration =
    (lib.evalModules {
      modules = [
        { _module.args.pkgs = pkgs; }
        ../apps
        {
          terraform.terraform.backend.consul = {
            scheme = "http";
            access_token = "";
            datacenter = "dc1";
            path = "terraform/state";
          };
        }
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
