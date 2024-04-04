{
  vault.policies.common-nut = {
    paths."kv/data/prod/common/nut".capabilities = [ "read" ];
    approles = [
      "brontes"
      "steropes"
    ];
  };

  vault.services.nut = {
    commonPolicies = [ "nut" ];
    hosts = [ "arges" ];
  };
}
