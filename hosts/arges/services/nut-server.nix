{
  power.ups = {
    enable = true;
    mode = "netserver";
    ups.tripplite = {
      driver = "usbhid-ups";
      port = "auto";
      directives = [
        ''vendorid = "09ae"''
        ''productid = "3024"''
      ];
    };
  };
}
