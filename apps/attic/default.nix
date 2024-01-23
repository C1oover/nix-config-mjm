{
  vault.databases.roles.attic = {
    ttl = "long";
  };
  vault.approles.roles.leto.tokenPolicies = [ "attic" ];

  vault.policies.attic.text = ''
    path "database/creds/attic" {
      capabilities = ["read"]
    }

    path "kv/data/attic" {
      capabilities = ["read"]
    }
  '';

  # minio.buckets.attic-caches = {};

  # minio.iamPolicies.attic = {
  #   users = ["attic"];
  #   document = {
  #     statement = [
  #       {
  #         actions = ["s3:*"];
  #         resources = [
  #           "arn:aws:s3:::attic-caches"
  #           "arn:aws:s3:::attic-caches/*"
  #         ];
  #       }
  #     ];
  #   };
  # };

  ingress.virtualHosts.attic = {
    upstream.service.name = "attic";
    enableAuthProxy = false;
  };
}
