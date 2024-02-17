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
  };

  vault.policies.mediaserver.paths = {
    "kv/data/mediaserver".capabilities = [ "read" ];
  };

  vault.approles.roles.chaos.tokenPolicies = [ "mediaserver" ];
}
