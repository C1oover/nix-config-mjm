{
  # the bucket resource includes how many bytes are stored in the bucket,
  # and uses a 32-bit int to do so. we easily exceed that, so having this
  # resource in the plan prevents using terraform
  #
  # terraform.resource.garage_bucket.loki-logs = {};
  # terraform.resource.garage_bucket_global_alias.loki-logs = {
  #   bucket_id = "\${garage_bucket.loki-logs.id}";
  #   alias = "loki-logs";
  # };
  # terraform.resource.garage_bucket_key.loki-logs_loki = {
  #   bucket_id = "\${garage_bucket.loki-logs.id}";
  #   access_key_id = "GK5670c04f8f981bf85639331b";
  #   owner = true;
  #   read = true;
  #   write = true;
  # };

  # minio.buckets.logs = {};

  # minio.iamPolicies.loki = {
  #   users = ["loki"];
  #   document = {
  #     statement = [
  #       {
  #         actions = ["s3:*"];
  #         resources = [
  #           "arn:aws:s3:::logs"
  #           "arn:aws:s3:::logs/*"
  #         ];
  #       }
  #     ];
  #   };
  # };

  vault.policies.loki.text = ''
    # Allow Loki to read its password for storing logs in Minio
    path "kv/data/loki" {
      capabilities = ["read"]
    }
  '';
}
