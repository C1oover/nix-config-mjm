{ config, lib, ... }:
let
  inherit (lib) concatMapAttrs mapAttrs;

  ingressIPs = {
    brontes = "2601:282:167f:3eec:dea6:32ff:fed5:d840";
    steropes = "2601:282:167f:3eec:dea6:32ff:fe96:bc05";
  };
in
{
  terraform.terraform.required_providers.cloudflare = {
    source = "registry.terraform.io/cloudflare/cloudflare";
    version = ">= 1.0.0";
  };

  terraform.provider.cloudflare = { };

  terraform.data.cloudflare_zone.external = {
    name = "midna.dev";
  };

  terraform.resource.cloudflare_record =
    mapAttrs (name: vhost: {
      zone_id = "\${data.cloudflare_zone.external.id}";
      type = "CNAME";
      inherit name;
      value = if vhost.useIPv4Proxy then "ingress4.midna.dev" else "ingress.midna.dev";
      proxied = false;
    }) config.ingress.virtualHosts
    // (concatMapAttrs (name: value: {
      "${name}_external" = {
        zone_id = "\${data.cloudflare_zone.external.id}";
        type = "AAAA";
        name = "ingress";
        inherit value;
        proxied = false;
      };
      "${name}4_external" = {
        zone_id = "\${data.cloudflare_zone.external.id}";
        type = "AAAA";
        name = "ingress4";
        inherit value;
        proxied = false;
      };
      "${name}_root" = {
        zone_id = "\${data.cloudflare_zone.external.id}";
        type = "AAAA";
        name = "@";
        inherit value;
        proxied = false;
      };
    }) ingressIPs)
    // {
      aion_ingress4 = {
        zone_id = "\${data.cloudflare_zone.external.id}";
        type = "A";
        name = "ingress4";
        value = "5.78.46.61";
        proxied = false;
      };
      aion_root = {
        zone_id = "\${data.cloudflare_zone.external.id}";
        type = "A";
        name = "@";
        value = "5.78.46.61";
        proxied = false;
      };
    };

  vault.policies.ingress = {
    paths."kv/data/ingress".capabilities = [ "read" ];
    approles = [
      "brontes"
      "steropes"
    ];
  };
}
