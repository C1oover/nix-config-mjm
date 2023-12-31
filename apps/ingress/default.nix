{
  pkgs,
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

  terraform.data.cloudflare_zone = {
    internal = {
      name = "mattmoriarity.com";
    };
    external = {
      name = "midna.dev";
    };
  };

  terraform.resource.cloudflare_record =
    lib.mapAttrs (name: vhost: {
      zone_id = "\${data.cloudflare_zone.${
        if vhost.external
        then "external"
        else "internal"
      }.id}";
      type = "CNAME";
      name =
        if vhost.external
        then name
        else "${name}.home";
      value =
        if vhost.external
        then "ingress.midna.dev"
        else "ingress.home.mattmoriarity.com";
      proxied = false;
    })
    config.ingress.virtualHosts
    // (lib.attrsets.mergeAttrsList (map (name: {
      "${name}_internal" = {
        zone_id = "\${data.cloudflare_zone.internal.id}";
        type = "AAAA";
        name = "ingress.home";
        value = ingressIPs.${name};
        proxied = false;
      };
      "${name}_external" = {
        zone_id = "\${data.cloudflare_zone.external.id}";
        type = "AAAA";
        name = "ingress";
        value = ingressIPs.${name};
        proxied = false;
      };
    }) (builtins.attrNames ingressIPs)));

  terraform.resource.gitlab_repository_file.ingress_dns = {
    project = "30"; # mjm/nix-config
    file_path = "hosts/common/optional/dns-server/home.mattmoriarity.com.ingress.zone";
    branch = "main";
    commit_message = "dns-server: update ingress cnames";
    author_name = "Homelab Automation";
    author_email = "homelab@matt.mattmoriarity.com";

    content = let
      filteredVhosts = builtins.attrNames (lib.filterAttrs (_name: vhost: !vhost.external) config.ingress.virtualHosts);
      encodedContent = pkgs.runCommandLocal "encoded-zone" {} ''
        cat <<EOF | base64 -w0 > $out
        ${builtins.concatStringsSep "\n" (map
          (name: "${name}  IN  CNAME ingress-http.service.consul.")
          filteredVhosts)}
        EOF
      '';
    in
      builtins.readFile "${encodedContent}";
  };
}
