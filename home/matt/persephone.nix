{
  pkgs,
  outputs,
  ...
}: {
  imports = [
    ./global

    ./features/desktop
    ./features/email
    ./features/firefox
    ./features/kitty
    ./features/newsboat
  ];

  home.packages = with pkgs; [
    discord
    outputs.packages.x86_64-linux.beeper
  ];

  programs.kitty.settings.focus_follows_mouse = "yes";
}
