{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.mjm.matrix-server;
  pkg = pkgs.mautrix-imessage;

  configFormat = pkgs.formats.yaml { };
  configFile = configFormat.generate "mautrix-imessage-config.yaml" {
    homeserver = {
      address = "http://localhost:6167";
      domain = "midna.dev";
      websocket_proxy = null;
    };
    appservice = {
      hostname = "127.0.0.1";
      port = port;
      database = {
        type = "sqlite3-fk-wal";
        uri = "file:mautrix-imessage.db?_txlock=immediate";
      };
      id = "imessage";
      bot.username = "imessagebot";
      bot.displayname = "iMessage bridge bot";
      bot.avatar = "mxc://maunium.net/tManJEpANASZvDVzvRvhILdX";
    };
    imessage = {
      platform = "mac-nosip";
      # TODO package with Nix
      imessage_rest_path = cfg.bridges.imessage.barcelonaMautrixPath;
      contacts_mode = "mac";
      unix_socket = "mautrix-imessage.sock";
    };
    bridge = {
      user = "@mjm:midna.dev";
      username_template = "imessage_{{.}}";
      displayname_template = "{{.}} (iMessage)";
      personal_filtering_spaces = true;
      convert_heif = true;
      convert_tiff = true;
      backfill.enable = true;
    };
  };

  # for now, this bridge needs to run in a Terminal window, or it won't have access
  # to contacts.
  #
  # ideally I can eventually get it to run as a launchd agent
  script = pkgs.writeShellScriptBin "run-mautrix-imessage" ''
    cd '${cfg.bridges.imessage.dataPath}'
    umask 0077

    test -f config.yaml && rm -f config.yaml
    cp '${configFile}' config.yaml
    chmod 0600 config.yaml

    if [ ! -f registration.yaml ]; then
      ${pkg}/bin/mautrix-imessage \
        --generate-registration \
        --config=config.yaml \
        --registration=registration.yaml
    fi
    chmod 0640 registration.yaml

    ${pkgs.yq}/bin/yq -s '.[0].appservice.as_token = .[1].as_token
      | .[0].appservice.hs_token = .[1].hs_token
      | .[0]' config.yaml registration.yaml \
      > config.yaml.tmp
    mv config.yaml.tmp config.yaml

    while true; do
      ${pkg}/bin/mautrix-imessage -c config.yaml -r registration.yaml
    done
  '';

  port = 29400;
in
{
  options.mjm.matrix-server.bridges.imessage = {
    enable = mkEnableOption "iMessage bridge";
    dataPath = mkOption {
      type = types.path;
      default = "/Users/mjm/Library/Application Support/mautrix-imessage";
    };
    barcelonaMautrixPath = mkOption {
      type = types.path;
      default = "/usr/local/bin/barcelona-mautrix";
    };
  };

  config = mkIf cfg.bridges.imessage.enable {
    nixpkgs.config.permittedInsecurePackages = [ "olm-3.2.16" ];
    environment.systemPackages = [ script ];

    users.users.mautrix-imessage = {
      uid = 590;
      gid = 590;
    };
    users.groups.mautrix-imessage = {
      gid = 590;
    };
    users.knownUsers = [ "mautrix-imessage" ];
    users.knownGroups = [ "mautrix-imessage" ];

    # These log files do need to be created and chown'd before the service can start.
    # launchd is bad.

    launchd.daemons.mautrix-imessage-tunnel = {
      command = "${pkgs.ghostunnel}/bin/ghostunnel server --use-workload-api --listen=launchd:Listener --target=localhost:29400 --disable-authentication";
      environment.SPIFFE_ENDPOINT_SOCKET = "unix:${config.mjm.spire.agent.socketPath}";
      serviceConfig = {
        StandardOutPath = "/Library/Logs/mautrix-imessage-tunnel.log";
        StandardErrorPath = "/Library/Logs/mautrix-imessage-tunnel.log";
        UserName = "mautrix-imessage";
        GroupName = "mautrix-imessage";
        Sockets.Listener = {
          SockServiceName = "29401";
          SockType = "stream";
          SockFamily = "IPv4";
        };
      };
    };
    launchd.daemons.mautrix-imessage-conduit-tunnel = {
      command = "${pkgs.ghostunnel}/bin/ghostunnel client --use-workload-api --listen=launchd:Listener --target=conduit.service.consul:6167 --verify-uri=spiffe://home.mattmoriarity.com/svc/conduit";
      environment.SPIFFE_ENDPOINT_SOCKET = "unix:${config.mjm.spire.agent.socketPath}";
      serviceConfig = {
        StandardOutPath = "/Library/Logs/mautrix-imessage-conduit-tunnel.log";
        StandardErrorPath = "/Library/Logs/mautrix-imessage-conduit-tunnel.log";
        UserName = "mautrix-imessage";
        GroupName = "mautrix-imessage";
        Sockets.Listener = {
          SockNodeName = "127.0.0.1";
          SockServiceName = "6167";
          SockType = "stream";
          SockFamily = "IPv4";
        };
      };
    };

    services.consul.services.mautrix-imessage = {
      inherit port;

      checks.up = {
        http.path = "/_matrix/mau/ready";
      };
    };
  };
}
