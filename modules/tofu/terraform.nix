{
  pkgs,
  lib,
  config,
  nodes,
  ...
}:
let
  inherit (lib)
    attrNames
    attrValues
    const
    filterAttrs
    flip
    foldl
    getAttr
    id
    length
    mapAttrs
    mkOption
    recursiveUpdate
    types
    ;
in
{
  # need this to be able to define non-host-specific terraform resources
  imports = [ ../nixos/terraform.nix ];

  options = {
    tofuConfig = {
      sanitized = mkOption {
        type = types.raw;
        readOnly = true;
      };
      final = mkOption {
        type = types.raw;
        readOnly = true;
      };
      json = mkOption {
        type = types.pathInStore;
        readOnly = true;
      };
    };
  };

  config = {
    tofuConfig.sanitized =
      let
        strip_nulls = true;
        sanitize =
          configuration:
          getAttr (builtins.typeOf configuration) {
            bool = configuration;
            int = configuration;
            string = configuration;
            str = configuration;
            list = map sanitize configuration;
            null = null;
            set =
              let
                pred = name: value: name != "_module" && name != "_ref" && name != "__functor";
                stripped_a = flip filterAttrs configuration (name: value: pred name value);
                stripped_b = flip filterAttrs configuration (name: value: pred name value && value != null);
                recursiveSanitized =
                  if strip_nulls then mapAttrs (const sanitize) stripped_b else mapAttrs (const sanitize) stripped_a;
              in
              if (length (attrNames configuration) == 0) then { } else recursiveSanitized;
          };
        cfg = foldl recursiveUpdate config.terraform (map (node: node.config.terraform) (attrValues nodes));
      in
      sanitize cfg;

    tofuConfig.final =
      let
        genericWhitelist =
          f: key:
          let
            attr = f config.tofuConfig.sanitized.${key};
          in
          if attr == { } || attr == null then { } else { ${key} = attr; };
        whitelist = genericWhitelist id;
        whitelistWithoutEmpty = genericWhitelist (filterAttrs (name: attr: attr != { }));
      in
      { }
      // (whitelistWithoutEmpty "data")
      // (whitelist "locals")
      // (whitelist "module")
      // (whitelist "output")
      // (whitelist "provider")
      // (whitelistWithoutEmpty "resource")
      // (whitelist "terraform")
      // (whitelist "variable");

    tofuConfig.json = (pkgs.formats.json { }).generate "config.tf.json" config.tofuConfig.final;
  };
}
