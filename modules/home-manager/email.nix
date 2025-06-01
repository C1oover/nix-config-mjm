{ lib, config, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.cloover.email;
in
{
  options.cloover.email = {
    enable = mkEnableOption "email account config";
  };

  config = mkIf cfg.enable {
    accounts.email.accounts.fastmail = {
      primary = true;
      flavor = "fastmail.com";
      address = "matt@mattmoriarity.com";
      aliases = [
        "mj@midna.dev"
        "cloover@midna.dev"
      ];
      realName = "Matt Moriarity";

      thunderbird.enable = true;
    };

    programs.thunderbird = {
      enable = true;

      profiles.matt = {
        isDefault = true;
      };
    };
  };
}
