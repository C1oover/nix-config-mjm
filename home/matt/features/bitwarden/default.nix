{ pkgs, ... }:
{
  programs.rbw = {
    enable = true;
    settings = {
      email = "matt@mattmoriarity.com";
      base_url = "https://pass.midna.dev/";
      pinentry = pkgs.pinentry-qt;
    };
  };
}
