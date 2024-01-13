let
  name = "loki";
  # loki 2.8.2
  image = "grafana/loki@sha256:b1da1d23037eb1b344cccfc5b587e30aed60ab4cad33b42890ff850aa3c4755d";
in {
  nomad.jobs.loki = {
    priority = 80;

    taskGroups.loki = {
      architecture = "arm64";

      ports.http.static = 3100;

      services = [
        {
          inherit name;
          port = 3100;
          connect.enable = true;
          metrics.enable = true;

          checks = [
            {
              http.path = "/ready";
              interval = 15;
              timeout = 3;
            }
          ];
        }
      ];

      tasks.loki = {
        docker = {
          inherit image;
          args = ["-config.file=$\${NOMAD_TASK_DIR}/loki.yml"];
        };
        cpu = 100;
        memory = 500;
        loggingTag = name;
        vault.policies = [name];
        vault.changeMode = "noop";

        templates."local/loki.yml" = {
          source = ./loki.yml;
          changeMode = "restart";
        };
      };
    };
  };

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

  minio.buckets.logs = {};

  minio.iamPolicies.loki = {
    users = ["loki"];
    document = {
      statement = [
        {
          actions = ["s3:*"];
          resources = [
            "arn:aws:s3:::logs"
            "arn:aws:s3:::logs/*"
          ];
        }
      ];
    };
  };

  vault.policies.loki.text = ''
    # Allow Loki to read its password for storing logs in Minio
    path "kv/data/loki" {
      capabilities = ["read"]
    }
  '';
}
