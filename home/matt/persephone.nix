{
  pkgs,
  outputs,
  config,
  ...
}: {
  imports = [
    ./global

    ./features/desktop
    ./features/email
    ./features/firefox
    ./features/games
    ./features/homelab
    ./features/kitty
    ./features/newsboat
  ];

  home.packages = with pkgs; [
    discord
    outputs.packages.x86_64-linux.beeper
    outputs.packages.x86_64-linux.controku
  ];

  home.file."${config.xdg.cacheHome}/controku/devices.json".text = builtins.toJSON [
    {
      name = "55\" TCL Roku TV";
      ip = "10.0.1.111";
    }
  ];
}
