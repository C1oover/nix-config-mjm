{ lib, nodes, ... }:
let
  inherit (lib)
    attrNames
    attrValues
    filter
    filterAttrs
    hasAttr
    mapAttrs
    mapAttrs'
    mergeAttrsList
    nameValuePair
    ;

  allNodes = attrValues nodes;
  policies = mergeAttrsList (map (node: node.config.vault.policies) allNodes);
  services = mergeAttrsList (map (node: node.config.vault.services) allNodes);

  policyNames = attrNames policies;
  serviceNames = attrNames services;

  mkPolicy = p: {
    inherit (p) name;
    policy = builtins.toJSON { path = p.paths; };
  };

  mkServicePolicy = svc: {
    name = "service-${svc.name}";
    policy = builtins.toJSON {
      path = {
        "kv/data/prod/services/${svc.name}".capabilities = [ "read" ];
      } // svc.paths;
    };
  };

  policiesForNode =
    node:
    (filter (p: hasAttr p node.config.vault.policies) policyNames)
    ++ (map (s: "service-${s}") (filter (s: hasAttr s node.config.vault.services) serviceNames));
in
{
  terraform.resource.vault_auth_backend.approle.type = "approle";

  terraform.resource.vault_approle_auth_backend_role =
    mapAttrs
      (name: node: {
        backend = "\${vault_auth_backend.approle.id}";
        role_name = name;
        token_policies = policiesForNode node;
      })
      (
        filterAttrs (_: node: node.config.vault.policies != { } || node.config.vault.services != { }) nodes
      );

  terraform.resource.vault_policy =
    mapAttrs (_: mkPolicy) policies
    // mapAttrs' (name: svc: nameValuePair "service-${name}" (mkServicePolicy svc)) services;
}
