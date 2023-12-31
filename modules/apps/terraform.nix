{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
with lib; {
  options = {
    terraform = mkOption {
      type = types.submoduleWith {
        description = "Terraform module";
        modules = [
          "${inputs.terranix}/core/terraform-options.nix"
          "${inputs.terranix}/modules"
          {_module.args.pkgs = pkgs;}
        ];
      };
    };

    terraformConfig = {
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
    terraformConfig.sanitized = let
      strip_nulls = true;
      sanitize = configuration:
        getAttr (builtins.typeOf configuration) {
          bool = configuration;
          int = configuration;
          string = configuration;
          str = configuration;
          list = map sanitize configuration;
          null = null;
          set = let
            pred = name: value: name != "_module" && name != "_ref" && name != "__functor";
            stripped_a =
              flip filterAttrs configuration
              (name: value: pred name value);
            stripped_b =
              flip filterAttrs configuration
              (name: value: pred name value && value != null);
            recursiveSanitized =
              if strip_nulls
              then mapAttrs (const sanitize) stripped_b
              else mapAttrs (const sanitize) stripped_a;
          in
            if (length (attrNames configuration) == 0)
            then {}
            else recursiveSanitized;
        };
    in
      sanitize config.terraform;

    terraformConfig.final = let
      genericWhitelist = f: key: let
        attr = f config.terraformConfig.sanitized.${key};
      in
        if attr == {} || attr == null
        then {}
        else {
          ${key} = attr;
        };
      whitelist = genericWhitelist id;
      whitelistWithoutEmpty = genericWhitelist (filterAttrs (name: attr: attr != {}));
    in
      {}
      // (whitelistWithoutEmpty "data")
      // (whitelist "locals")
      // (whitelist "module")
      // (whitelist "output")
      // (whitelist "provider")
      // (whitelistWithoutEmpty "resource")
      // (whitelist "terraform")
      // (whitelist "variable");

    terraformConfig.json = (pkgs.formats.json {}).generate "config.tf.json" config.terraformConfig.final;
  };
}
