{ pkgs, config, ... }:

{
  imports = [
    ./global
  ];

  home.packages = with pkgs; [
    gh
    google-cloud-sdk
    teleport
    zoom-us
  ];

  home.shellAliases = {
    db-stage = "tsh -k no db login --db-user=teleport-rw@slab-stage.iam --db-name=slab slab-sql-stage-pg14";
    db-prod-replica = "tsh -k no db login --db-user=teleport-ro@slab-prod.iam --db-name=slab slab-sql-prod-replica-pg14-0";
  };

  home.dock = {
    enable = true;
    entries = [
      { path = "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app/"; }
      { path = "/Applications/Firefox.app/"; }
      { path = "/System/Applications/Messages.app/"; }
      { path = "/System/Applications/Mail.app/"; }
      { path = "${pkgs.zoom-us}/Applications/zoom.us.app/"; }
      { path = "${pkgs.slack}/Applications/Slack.app/"; }
      { path = "/Applications/Fantastical.app/"; }
      { path = "/Applications/1Password.app/"; }
      { path = "/Applications/Slab.app/"; }
      { path = "/Applications/GitHub Desktop.app/"; }
      { path = "${pkgs.iterm2}/Applications/iTerm2.app/"; }
      { path = "/Applications/Dash.app/"; }
      { path = "/Applications/Postico 2.app/"; }
      { path = "/Applications/Discord.app"; }
      {
        path = "${config.home.homeDirectory}/Downloads/";
        section = "others";
        options = "--sort dateadded --view grid --display folder";
      }
    ];
  };

  programs.git.userEmail = "matt@slab.com";
}
