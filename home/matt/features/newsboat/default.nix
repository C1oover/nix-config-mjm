{pkgs, ...}: let
  githubProjects = [
    "hashicorp/consul"
    "hashicorp/vault"
    "hashicorp/nomad"
    "grafana/grafana"
    "grafana/loki"
    "sissbruecker/linkding"
    "prometheus-pve/prometheus-pve-exporter"
    "0xERR0R/blocky"
    "prometheus/consul_exporter"
    "prometheus/pushgateway"
    "prometheus/blackbox_exporter"
    "lldap/lldap"
    "actualbudget/actual"
    "vrana/adminer"
  ];

  githubUrls =
    map (prj: {
      title = "${prj} releases";
      url = "https://github.com/${prj}/releases.atom";
      tags = ["release"];
    })
    githubProjects;
in {
  programs.newsboat = {
    enable = true;
    autoReload = true;
    browser = "\"/usr/bin/open -a ${pkgs.firefox-bin}/Applications/Firefox.app -u %u\"";
    urls =
      [
        {
          title = "Chris Siebenmann";
          url = "https://utcc.utoronto.ca/~cks/space/blog/?atom";
          tags = ["blog"];
        }
        {
          title = "Xe Iaso";
          url = "https://xeiaso.net/blog.rss";
          tags = ["blog"];
        }
      ]
      ++ githubUrls;
    extraConfig = ''
      text-width 100
    '';
  };
}
