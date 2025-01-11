{
  cliraop,
  oldpkgs,
  providers ? [ ],
}:

(oldpkgs.music-assistant.override { inherit providers; }).overridePythonAttrs (oldAttrs: {
  preBuild = ''
    ln -sf ${cliraop}/bin/cliraop music_assistant/providers/airplay/bin/cliraop-linux-x86_64
  '';
})
