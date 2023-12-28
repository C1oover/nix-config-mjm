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
  };
}
