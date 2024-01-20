{inputs, ...}: {
  perSystem = {
    pkgs,
    lib,
    system,
    ...
  }: let
    opentofu = pkgs.opentofu.withPlugins (p: [
      p.consul
      p.gitlab
      p.minio
      p.nomad
      p.vault
      p.cloudflare
      p.proxmox
      (p.mkProvider {
        owner = "prologin";
        repo = "terraform-provider-garage";
        rev = "v0.0.1";
        spdx = "AGPL-3.0-only";
        hash = "sha256-JNeTJ5nt8IvYk9M8fUEiGTLUDd9QHS6PeBwWDjRzx4g=";
        vendorHash = "sha256-6PXFDwQRPJU6+X1pUuzIaTiQNVPJjOUDMsnDXBivO5A=";
        homepage = "https://registry.terraform.io/providers/prologin/garage";
      })
    ]);
    terraformConfiguration =
      (lib.evalModules {
        modules = [
          {_module.args.pkgs = pkgs;}
          ../apps
          {terraform = ./config.nix;}
        ];
        specialArgs = {inherit inputs;};
      })
      .config
      .terraformConfig
      .json;
  in {
    packages.terraform = opentofu;

    devenv.shells.default = {
      env = {
        CONSUL_HTTP_ADDR = "consul.service.consul:8500";
        NOMAD_ADDR = "http://nomad.service.consul:4646";
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

    apps = builtins.mapAttrs (_: script: {program = toString script;}) (pkgs.callPackages ./scripts.nix {
      inherit opentofu terraformConfiguration;
    });
  };
}
