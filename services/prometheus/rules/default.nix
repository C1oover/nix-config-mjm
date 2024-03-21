{
  services.prometheus.ruleFiles = [
    ./dns_alerts.yml
    ./node_alerts.yml
  ];
}
