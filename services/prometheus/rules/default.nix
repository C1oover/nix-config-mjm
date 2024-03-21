{
  services.prometheus.ruleFiles = [
    ./backup_alerts.yml
    ./consul_alerts.yml
    ./dns_alerts.yml
    ./ingress_alerts.yml
    ./node_alerts.yml
    ./ups_alerts.yml
  ];
}
