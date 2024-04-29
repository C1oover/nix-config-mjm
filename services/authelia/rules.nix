[
  {
    domain = "links.midna.dev";
    resources = [ "^/api/.*$" ];
    policy = "bypass";
  }
  {
    domain = "feeds.midna.dev";
    resources = [
      "^/v1/.*$"
      "^/accounts/ClientLogin$"
      "^/reader/api/0/.*$"
    ];
    policy = "bypass";
  }
  {
    domain = "downloads.midna.dev";
    resources = [ "^/api.*$" ];
    policy = "bypass";
  }
  {
    domain = "tv.midna.dev";
    resources = [ "^/api/.*$" ];
    policy = "bypass";
  }
  {
    domain = "movies.midna.dev";
    resources = [ "^/api/.*$" ];
    policy = "bypass";
  }
  {
    domain = "albums.midna.dev";
    resources = [ "^/api/.*$" ];
    policy = "bypass";
  }
  {
    domain = "home.midna.dev";
    resources = [ "^/api/.*$" ];
    policy = "bypass";
  }
  {
    domain = "music.midna.dev";
    resources = [ "^/rest/.*$" ];
    policy = "bypass";
  }
]
