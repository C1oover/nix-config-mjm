{ pkgs, config, ... }:
{
  home.packages = with pkgs; [ controku ];

  home.file."${config.xdg.cacheHome}/controku/devices.json".text = builtins.toJSON [
    {
      name = ''55" TCL Roku TV'';
      ip = "10.1.0.111";
    }
  ];
}
