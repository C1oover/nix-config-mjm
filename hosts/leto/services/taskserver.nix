{
  services.taskserver = {
    enable = true;
    fqdn = "tasks.midna.dev";
    listenHost = "::";
    openFirewall = true;
    organisations.home.users = ["mjm"];
  };
}
