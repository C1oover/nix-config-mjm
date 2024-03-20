{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      system,
      ...
    }:
    let
      # hash mismatch in the go modules for vault rn
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
            { terraform = ./config.nix; }
          ];
          specialArgs = {
            inherit inputs;
          };
        }).config.terraformConfig.json;

      tofu-scripts = pkgs.callPackage ./scripts { inherit vault opentofu terraformConfiguration; };
    in
    {
      packages = {
        inherit opentofu tofu-scripts;
        terraform = opentofu;
      };

      devenv.shells.default = {
        env = {
          CONSUL_HTTP_ADDR = "consul.service.consul:8500";
          VAULT_ADDR = "http://vault.service.consul:8200";
        };

        packages = with pkgs; [
          vault
          openssh
        ];

        languages.terraform.enable = true;
        languages.terraform.package = opentofu;

        scripts.tf.exec = ''
          cd terraform
          ${lib.getExe opentofu} "$@"
        '';
      };

      apps = lib.genAttrs tofu-scripts.scripts (script: {
        program = "${tofu-scripts}/bin/${script}";
      });
    };
}
