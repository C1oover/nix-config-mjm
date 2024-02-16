{
  vault.policies.otel-collector.text = ''
    # Allow the OpenTelemetry collector to read the Honeycomb API key
    path "kv/data/honeycomb" {
      capabilities = ["read"]
    }
  '';

  vault.approles.roles.leto.tokenPolicies = [ "otel-collector" ];
}
