let
  inputs = import ./npins;
  pkgs = import inputs.nixos { config.allowUnfree = true; };
in
pkgs.mkShell {
  packages = builtins.attrValues {
    inherit (pkgs)
      colmena
      just
      npins
      terraform-ls
      vault-bin
      ;

    inherit (import ./terraform { inherit pkgs; }) opentofu;
  };

  env = {
    CONSUL_HTTP_ADDR = "consul.service.consul:8500";
    VAULT_ADDR = "http://vault.service.consul:8200";
  };
}
