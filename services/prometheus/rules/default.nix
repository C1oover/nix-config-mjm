{
  services.prometheus.ruleFiles = [
    ./backup_alerts.yml
    ./dns_alerts.yml
    ./node_alerts.yml
  ];
}
