{
  ingress.virtualHosts = {
    media = {
      upstream.service.name = "jellyfin";
      enableAuthProxy = false;
    };
    downloads = {
      upstream.service.name = "sabnzbd";
    };
    tv = {
      upstream.service.name = "sonarr";
    };
    movies = {
      upstream.service.name = "radarr";
    };
    books = {
      upstream.service.name = "readarr";
    };
    audiobooks = {
      upstream.service.name = "readarr-audio";
    };
    tube = {
      upstream.service.name = "invidious";
      enableAuthProxy = false;
    };
    music = {
      upstream.service.name = "navidrome";
    };
  };

  vault.services.media-server = {
    commonPolicies = [ "backups" ];
    hosts = [ "chaos" ];
  };
}
