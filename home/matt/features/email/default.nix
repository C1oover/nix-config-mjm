{
  accounts.email.accounts.fastmail = {
    primary = true;
    flavor = "fastmail.com";
    address = "matt@mattmoriarity.com";
    aliases = [
      "mj@midna.dev"
      "mjm@midna.dev"
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
}
