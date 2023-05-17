{pkgs, ...}: let
  addons = pkgs.callPackage ./addons {};
in {
  home.packages = with pkgs; [
    nur.repos.rycee.mozilla-addons-to-nix
  ];

  programs.firefox = {
    enable = true;
    package = pkgs.firefox-bin;
    profiles.matt = {
      settings = {
        "browser.startup.homepage" = "https://homelab.home.mattmoriarity.com/";
        "extensions.activeThemeID" = "{c827c446-3d00-4160-a992-3ebcbe6d81a6}";
        "security.enterprise_roots.enabled" = true;
      };
      extensions = with pkgs.nur.repos; [
        rycee.firefox-addons.onepassword-password-manager
        bandithedoge.firefoxAddons.tree-style-tab
        bandithedoge.firefoxAddons.ublock-origin
        addons.minimaltwitter
        addons.shinigami-eyes
        addons.linkding-extension
        addons.linkding-injector
        addons.catppuccin-latte-mauve
      ];
    };
  };
}
