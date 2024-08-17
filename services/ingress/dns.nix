{ lib, config, ... }:
let
  inherit (lib)
    attrValues
    concatMapAttrs
    mapAttrs
    mkIf
    ;

  # would kinda be nice if we could get these from the node configs but
  # they don't declare it anywhere
  ingressIPs = {
    brontes = "2601:282:167f:3eec:dea6:32ff:fed5:d840";
    steropes = "2601:282:167f:3eec:dea6:32ff:fe96:bc05";
  };
in
{
  config = mkIf config.mjm.ingress.enable {
    terraform.terraform.required_providers.cloudflare = {
      source = "registry.terraform.io/cloudflare/cloudflare";
      version = ">= 1.0.0";
    };
    terraform.terraform.required_providers.desec = {
      source = "registry.terraform.io/Valodim/desec";
      version = ">= 0.5.0";
    };

    terraform.provider.cloudflare = { };
    terraform.provider.desec = { };

    terraform.data.cloudflare_zone.external = {
      name = "midna.dev";
    };

    terraform.resource.desec_domain.midna-dev = {
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

    terraform.resource.desec_rrset =
      mapAttrs (subname: vhost: {
        domain = "\${desec_domain.midna-dev.id}";
        type = "CNAME";
        inherit subname;
        records = [ (if vhost.useIPv4Proxy then "ingress4.midna.dev." else "ingress.midna.dev.") ];
        ttl = 3600;
      }) config.ingress.virtualHosts
      // {
        ingress_aaaa = {
          domain = "\${desec_domain.midna-dev.id}";
          type = "AAAA";
          subname = "ingress";
          records = attrValues ingressIPs;
          ttl = 3600;
        };
        ingress4_aaaa = {
          domain = "\${desec_domain.midna-dev.id}";
          type = "AAAA";
          subname = "ingress4";
          records = attrValues ingressIPs;
          ttl = 3600;
        };
        root_aaaa = {
          domain = "\${desec_domain.midna-dev.id}";
          type = "AAAA";
          subname = "";
          records = attrValues ingressIPs;
          ttl = 3600;
        };
        ingress4_a = {
          domain = "\${desec_domain.midna-dev.id}";
          type = "A";
          subname = "ingress4";
          records = [ "5.78.46.61" ];
          ttl = 3600;
        };
        root_a = {
          domain = "\${desec_domain.midna-dev.id}";
          type = "A";
          subname = "";
          records = [ "5.78.46.61" ];
          ttl = 3600;
        };
        pages_wildcard = {
          domain = "\${desec_domain.midna-dev.id}";
          type = "CNAME";
          subname = "*.pages";
          records = [ "ingress.midna.dev." ];
          ttl = 3600;
        };
        www = {
          domain = "\${desec_domain.midna-dev.id}";
          type = "CNAME";
          subname = "www";
          records = [ "ingress.midna.dev." ];
          ttl = 3600;
        };

        # not really ingress related but nowhere else to put them
        dkim_1 = {
          domain = "\${desec_domain.midna-dev.id}";
          type = "CNAME";
          subname = "fm1._domainkey";
          records = [ "fm1.midna.dev.dkim.fmhosted.com." ];
          ttl = 3600;
        };
        dkim_2 = {
          domain = "\${desec_domain.midna-dev.id}";
          type = "CNAME";
          subname = "fm2._domainkey";
          records = [ "fm2.midna.dev.dkim.fmhosted.com." ];
          ttl = 3600;
        };
        dkim_3 = {
          domain = "\${desec_domain.midna-dev.id}";
          type = "CNAME";
          subname = "fm3._domainkey";
          records = [ "fm3.midna.dev.dkim.fmhosted.com." ];
          ttl = 3600;
        };
        root_mx = {
          domain = "\${desec_domain.midna-dev.id}";
          type = "MX";
          subname = "";
          records = [
            "10 in1-smtp.messagingengine.com."
            "20 in2-smtp.messagingengine.com."
          ];
          ttl = 3600;
        };
        wildcard_mx = {
          domain = "\${desec_domain.midna-dev.id}";
          type = "MX";
          subname = "*";
          records = [
            "10 in1-smtp.messagingengine.com."
            "20 in2-smtp.messagingengine.com."
          ];
          ttl = 3600;
        };
        spf = {
          domain = "\${desec_domain.midna-dev.id}";
          type = "TXT";
          subname = "";
          records = [ "v=spf1 include:spf.messagingengine.com ?all" ];
          ttl = 3600;
        };
      };
  };
}
