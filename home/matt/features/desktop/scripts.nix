{
  bash,
  resholve,
  light,
  pulseaudio,
}:
let
  interpreter = "${bash}/bin/bash";
in
{
  night-mode =
    resholve.writeScriptBin "night-mode"
      {
        inherit interpreter;
        inputs = [
          light
          pulseaudio
        ];
      }
      ''
        pactl set-sink-volume @DEFAULT_SINK@ 30%
        light -S 1
      '';
}
