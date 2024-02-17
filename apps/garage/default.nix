{ lib, ... }:
{
  vault.policies.garage.paths = {
    "kv/data/garage".capabilities = [ "read" ];
  };

  vault.approles.roles =
    lib.genAttrs
      [
        "leto"
        "chaos"
        "helios"
      ]
      (_name: { tokenPolicies = [ "garage" ]; });
}
