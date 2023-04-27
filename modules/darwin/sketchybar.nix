{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.sketchybar;

  toSketchybarConfig = opts:
    concatStringsSep "\n" ([
      "#!${pkgs.bash}/bin/bash"
      ""
      "generated_cfg=("
    ] ++ (mapAttrsToList (p: v: "  ${p}=${toString v}") opts) ++ [
      ")"
      ""
      ("sketchybar --bar \"$" + "{generated_cfg[@]}\"")
      ""
    ]);

  configFile = mkIf (cfg.config != { } || cfg.extraConfig != "")
    "${pkgs.writeScript "sketchybarrc" (
      (if (cfg.config != {})
       then "${toSketchybarConfig cfg.config}"
       else "")
      + optionalString (cfg.extraConfig != "") cfg.extraConfig)}";
in

{
  options = with types; {
    services.sketchybar.enable = mkOption {
      type = bool;
      default = false;
      description = "Whether to enable the sketchybar statusbar.";
    };

    services.sketchybar.package = mkOption {
      type = path;
      default = pkgs.sketchybar;
      description = "The sketchybar package to use.";
    };

    services.sketchybar.config = mkOption {
      type = attrs;
      default = { };
      example = literalExpression ''
        {
          clock_format     = "%R";
          background_color = "0xff202020";
          foreground_color = "0xffa8a8a8";
        }
      '';
      description = ''
        Key/value pairs to pass to sketchybar's main bar, via the configuration file.
      '';
    };

    services.sketchybar.extraConfig = mkOption {
      type = str;
      default = "";
      example = literalExpression ''
        echo "sketchybar config loaded..."
      '';
      description = ''
        Extra arbitrary configuration to append to the configuration file.
      '';
    };
  };

  config = mkIf (cfg.enable) {
    environment.systemPackages = [ cfg.package ];

    launchd.user.agents.sketchybar = {
      serviceConfig.ProgramArguments = [ "${cfg.package}/bin/sketchybar" ]
        ++ optionals (cfg.config != { } || cfg.extraConfig != "") [ "--config" configFile ];

      serviceConfig.KeepAlive = true;
      serviceConfig.RunAtLoad = true;
      serviceConfig.EnvironmentVariables = {
        PATH = "${cfg.package}/bin:${config.environment.systemPath}";
      };
    };
  };
}
