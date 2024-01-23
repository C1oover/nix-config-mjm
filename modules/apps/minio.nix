{ config, lib, ... }:
with lib;
let
  cfg = config.minio;

  bucketType =
    with lib;
    { name, ... }:
    {
      options = {
        name = mkOption {
          type = types.str;
          default = name;
        };
      };
    };

  iamPolicyType =
    with lib;
    { name, ... }:
    {
      options = {
        name = mkOption {
          type = types.str;
          default = name;
        };
        document = mkOption { type = types.attrs; };
        users = mkOption {
          default = [ ];
          type = types.listOf types.str;
        };
      };
    };
in
{
  options.minio = {
    enable = mkEnableOption "minio";
    server = mkOption {
      default = null;
      type = types.nullOr types.str;
    };
    buckets = mkOption {
      default = { };
      type = types.attrsOf (types.submodule bucketType);
    };
    iamPolicies = mkOption {
      default = { };
      type = types.attrsOf (types.submodule iamPolicyType);
    };
  };

  config = mkIf cfg.enable {
    terraform.terraform.required_providers.minio = {
      source = "registry.terraform.io/aminueza/minio";
      version = ">= 1.0.0";
    };
    terraform.provider.minio.minio_server = cfg.server;

    terraform.resource.minio_s3_bucket =
      lib.attrsets.mapAttrs'
        (name: value: {
          name = builtins.replaceStrings [ "-" ] [ "_" ] name;
          value = {
            bucket = name;
          };
        })
        cfg.buckets;

    terraform.data.minio_iam_policy_document =
      builtins.mapAttrs (_name: value: value.document)
        cfg.iamPolicies;

    terraform.resource.minio_iam_policy =
      builtins.mapAttrs
        (name: _value: {
          inherit name;
          policy = "\${data.minio_iam_policy_document.${name}.json}";
        })
        cfg.iamPolicies;

    terraform.resource.minio_iam_user_policy_attachment =
      let
        pairs =
          builtins.concatMap
            (
              policy:
              map
                (userName: {
                  policyName = policy.name;
                  inherit userName;
                })
                policy.users
            )
            (builtins.attrValues cfg.iamPolicies);
      in
      builtins.listToAttrs (
        map
          (
            { policyName, userName }:
            {
              name = "${policyName}_${userName}";
              value = {
                policy_name = "\${minio_iam_policy.${policyName}.name}";
                user_name = userName;
              };
            }
          )
          pairs
      );
  };
}
