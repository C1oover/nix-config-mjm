{pkgs, ...}: {
  accounts.email.accounts.fastmail = {
    primary = true;
    flavor = "fastmail.com";
    address = "matt@mattmoriarity.com";
    realName = "Matt Moriarity";

    thunderbird.enable = true;
  };

  programs.thunderbird = {
    enable = true;
    package = pkgs.thunderbird-wayland;

    profiles.matt = {
      isDefault = true;
      settings = {
        "layout.css.devPixelsPerPx" = "1.5";
      };
    };
  };
}
