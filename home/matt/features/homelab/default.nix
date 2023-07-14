{
  pkgs,
  inputs,
  ...
}: let
  devenv = inputs.devenv.packages.${pkgs.stdenv.hostPlatform.system}.default;

  envVars = {
    NOMAD_ADDR = "http://nomad.service.consul:4646";
    CONSUL_HTTP_ADDR = "http://consul.service.consul:8500";
    VAULT_ADDR = "http://vault.service.consul:8200";
  };
in {
  home.packages = with pkgs; [
    consul
    devenv
    minio-client
    # nomad (1.5) isn't building correctly on macOS rn
    nomad_1_4
    tarsnap
    vault
    wander
  ];

  home.sessionVariables = envVars;
}
