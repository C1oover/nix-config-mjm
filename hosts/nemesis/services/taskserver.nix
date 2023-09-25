{
  services.taskserver = {
    enable = true;
    fqdn = "nemesis.home.mattmoriarity.com";
    listenHost = "0.0.0.0";
    openFirewall = true;
    organisations.home.users = ["mjm"];
  };
}
