{ config, inputs, outputs, ... }:

{
  imports = [
    inputs.home-manager.darwinModules.home-manager
    inputs.agenix.darwinModules.default

    ./dock.nix
    ./keyboard.nix
    ./nix.nix
  ] ++ (builtins.attrValues outputs.darwinModules);

  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    extraSpecialArgs = { inherit inputs outputs; };
  };

  time.timeZone = "America/Denver";

  programs.zsh.enable = true;
  programs.nix-index.enable = true;

  security.pam.enableSudoTouchIdAuth = true;

  users.users.matt = {
    home = "/Users/matt";
  };

  environment.systemPackages = [ inputs.agenix.packages.${config.nixpkgs.system}.default ];
}
