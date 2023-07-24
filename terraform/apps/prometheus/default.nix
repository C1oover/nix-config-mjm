{
  vault.approles.roles.prometheus = {
    tokenPolicies = ["prometheus" "alertmanager"];
  };

  vault.policies.prometheus.text = ''
    # Allow Prometheus to scrape Vault's metrics endpoint
    path "sys/metrics" {
      capabilities = ["read", "list"]
    }

    # Allow Prometheus to issue itself client certificates for accessing Nomad's metrics
    path "pki-int/issue/nomad-cluster" {
      capabilities = ["update"]
    }
  '';

  vault.policies.alertmanager.text = ''
    # Allow alertmanager to read Pushover secrets for sending notifications
    path "kv/data/pushover" {
      capabilities = ["read"]
    }

    path "kv/data/pagerduty" {
      capabilities = ["read"]
    }
  '';

  ingress.virtualHosts = {
    alertmanager = {
      upstream.service.name = "alertmanager";
    };

    prometheus = {
      upstream.service.name = "prometheus";
    };
  };
}
