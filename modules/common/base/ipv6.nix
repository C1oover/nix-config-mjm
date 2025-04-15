{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.mjm.ipv6Prefix = mkOption {
    type = types.str;
  };

  config = {
    mjm.ipv6Prefix = "2601:282:0:30e0";
  };
}
