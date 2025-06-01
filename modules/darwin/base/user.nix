{ config, ... }:
let
  username = config.cloover.username;
in
{
  users.users.${username}.home = "/Users/${username}";
}
