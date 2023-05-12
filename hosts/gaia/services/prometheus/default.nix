{
  imports = [
    ./jobs
  ];

  services.prometheus = {
    enable = true;
    checkConfig = "syntax-only";

    globalConfig = {
      scrape_interval = "60s";
      evaluation_interval = "30s";
    };
  };
}
