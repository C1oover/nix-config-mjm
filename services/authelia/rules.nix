[
  {
    domain = "links.midna.dev";
    resources = [ "^/api/.*$" ];
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
    domain = "music.midna.dev";
    resources = [ "^/rest/.*$" ];
    policy = "bypass";
  }
]
