{
  config,
  lib,
  ...
}: let
  ingressIPs = {
    brontes = "2601:282:167f:3eec:dea6:32ff:fed5:d840";
    steropes = "2601:282:167f:3eec:dea6:32ff:fe96:bc05";
  };
in {
  terraform.terraform.required_providers.cloudflare = {
    source = "registry.terraform.io/cloudflare/cloudflare";
    version = ">= 1.0.0";
  };

  terraform.provider.cloudflare = {};

  terraform.data.cloudflare_zone.external = {
    name = "midna.dev";
  };

  terraform.resource.cloudflare_record =
    lib.mapAttrs (name: vhost: {
      zone_id = "\${data.cloudflare_zone.external.id}";
      type = "CNAME";
      inherit name;
      value = "ingress.midna.dev";
      proxied = false;
    })
    config.ingress.virtualHosts
    // (lib.attrsets.mergeAttrsList (map (name: {
      "${name}_external" = {
        zone_id = "\${data.cloudflare_zone.external.id}";
        type = "AAAA";
        name = "ingress";
        value = ingressIPs.${name};
        proxied = false;
      };
    }) (builtins.attrNames ingressIPs)));
}
