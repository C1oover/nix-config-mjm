{
  cliraop,
  oldpkgs,
  providers ? [ ],
}:

(oldpkgs.music-assistant.override { inherit providers; }).overrideAttrs (oldAttrs: {
  preBuild = ''
    ln -sf ${cliraop}/bin/cliraop music_assistant/server/providers/airplay/bin/cliraop-linux-x86_64
  '';
})
