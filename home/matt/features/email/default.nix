{
  accounts.email.accounts.fastmail = {
    primary = true;
    flavor = "fastmail.com";
    address = "matt@mattmoriarity.com";
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
