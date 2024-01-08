{
  ingress.virtualHosts = {
    media = {
      upstream.service.name = "jellyfin";
      external = true;
      enableAuthProxy = false;
    };
    downloads = {
      upstream.service.name = "sabnzbd";
      external = true;
    };
    tv = {
      upstream.service.name = "sonarr";
      external = true;
    };
    movies = {
      upstream.service.name = "radarr";
      external = true;
    };
  };
}
