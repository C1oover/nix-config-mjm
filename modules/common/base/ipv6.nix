{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.cloover.ipv6Prefix = mkOption {
    type = types.str;
  };

  config = {
    cloover.ipv6Prefix = "2601:282:0:30e0";
  };
}
