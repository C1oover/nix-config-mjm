{ modulesPath, ... }:
let
  my-nixpkgs = builtins.fetchTarball {
    url = "https://github.com/mjm/nixpkgs/archive/f09c7eca9ec3d6bb1b025a7e3c31b4f030245044.tar.gz";
    sha256 = "1l10n667z2blr1i307xqypdnrahad0lspc64d83z98qhxx5br7xp";
  };
in
{
  imports = [ "${my-nixpkgs}/nixos/modules/services/networking/consul.nix" ];
  disabledModules = [ "${modulesPath}/services/networking/consul.nix" ];
}
