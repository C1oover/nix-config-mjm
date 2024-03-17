{
  mjm.state.directories = [ "/var/lib/heisenbridge" ];

  services.heisenbridge = {
    enable = true;
    homeserver = "http://localhost:6167";
    debug = true;
    owner = "@mjm:midna.dev";
    namespaces = {
      users = [
        {
          regex = "@irc_.*";
          exclusive = true;
        }
      ];
      aliases = [ ];
      rooms = [ ];
    };
  };
}
