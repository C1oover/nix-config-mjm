{ config, ... }:
let
  username = config.mjm.username;
in
{
  users.users.${username}.home = "/Users/${username}";
}
