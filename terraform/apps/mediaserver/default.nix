{
  ingress.virtualHosts = {
    downloads = {
      upstream.service.name = "sabnzbd";
    };
    tv = {
      upstream.service.name = "sonarr";
    };
  };
}
