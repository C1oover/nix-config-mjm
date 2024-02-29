{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkMerge;
in
{
  config = mkMerge [
    (mkIf (config.specialisation != { }) {
      services.xserver.videoDrivers = [ "nvidia" ];

      # needed for wayland to work at all
      hardware.nvidia.modesetting.enable = true;

      hardware.nvidia.powerManagement.enable = true;

      hardware.opengl.extraPackages = [
        pkgs.libvdpau-va-gl
        pkgs.nvidia-vaapi-driver
      ];

      # without this, discord won't run
      environment.sessionVariables.NIXOS_OZONE_WL = "1";
    })
    {
      specialisation.nouveau = {
        # might not be anything to do here, just not have the nvidia settings
      };
    }
  ];
}
