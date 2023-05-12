{
  imports = [
    ./jobs
  ];

  services.prometheus = {
    enable = true;
    checkConfig = "syntax-only";
  };
}
