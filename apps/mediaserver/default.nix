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
  };

  vault.policies.mediaserver = {
    paths."kv/data/mediaserver".capabilities = [ "read" ];
    approles = [ "chaos" ];
  };
}
