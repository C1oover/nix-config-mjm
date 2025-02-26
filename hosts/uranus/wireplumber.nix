{
  services.pipewire.wireplumber = {
    extraConfig.desk-devices = {
      "context.properties" = {
        "log.level" = "I";
      };

      "monitor.alsa.rules" = [
        # disable the displayport audio from the graphics card
        {
          matches = [
            { "api.alsa.card.name" = "HDA ATI HDMI"; }
          ];
          actions = {
            update-props = {
              "device.disabled" = true;
            };
          };
        }

        # disable nodes that i don't use to clean up the choices
        {
          matches = [
            {
              "media.class" = "Audio/Sink";
              "api.alsa.card.name" = "Yeti Stereo Microphone";
            }
            {
              "media.class" = "Audio/Source";
              "api.alsa.card.name" = "HD Pro Webcam C920";
            }
            {
              "media.class" = "Audio/Source";
              "api.alsa.card.name" = "Studio Display";
            }
            {
              "media.class" = "Audio/Source";
              "api.alsa.card.name" = "HD-Audio Generic";
            }
          ];
          actions = {
            update-props = {
              "node.disabled" = true;
            };
          };
        }
      ];
    };
  };
}
