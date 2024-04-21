{ inputs, modulesPath, ... }:
{
  imports = [ "${inputs.nixos-consul-services}/nixos/modules/services/networking/consul.nix" ];
  disabledModules = [ "${modulesPath}/services/networking/consul.nix" ];
}
