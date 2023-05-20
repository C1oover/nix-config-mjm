let
  upstreams = [
    "8.8.8.8"
    "8.8.4.4"
    "1.1.1.1"
    "1.0.0.1"
  ];
in {
  services.blocky = {
    enable = true;
    settings = {
      bootstrapDns = map (ip: {upstream = ip;}) upstreams;
      upstream.default = upstreams;
      blocking = {
        blackLists.ads = [
          "https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt"
          "https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt"
          "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
        ];
        clientGroupsBlock.default = ["ads"];
      };
      ports.dns = "127.0.0.1:1053";
      ports.http = 4000;
      prometheus = {
        enable = true;
        path = "/metrics";
      };
      caching.maxTime = "-1s"; # disable caching since it seems buggy
    };
  };

  networking.firewall.allowedTCPPorts = [
    4000
  ];
}
