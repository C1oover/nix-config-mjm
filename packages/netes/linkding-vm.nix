{
  lib,
  netes,
  writeShellScript,
  writeShellScriptBin,
  writeText,
  uwsgi,
  linkding,
  mailcap,
  socat,
  busybox,
  bashInteractive,
  pkgsMusl,
}:

let

  # inherit (pkgsMusl)
  #   busybox
  #   socat
  #   mailcap
  #   linkding
  #   uwsgi
  #   ;

  env = {
    LD_DATA_DIR = "/tmp/linkding";
    LD_SUPERUSER_NAME = "mjm";
    LD_SUPERUSER_PASSWORD = "password";
    LD_CSRF_TRUSTED_ORIGINS = "https://linkding.lvh.me:8443";
    PYTHONPATH = "${linkding.python.pkgs.makePythonPath linkding.propagatedBuildInputs}:${linkding}/lib/linkding";
  };

  uwsgi' = uwsgi.override {
    plugins = [ "python3" ];
    withSystemd = false;
  };
  uwsgiCfg = writeText "linkding-uwsgi.ini" ''
    [uwsgi]
    master = True
    cheap = True
    protocol = http
    need-plugin = python3
    module = siteroot.wsgi:application
    env = DJANGO_SETTINGS_MODULE=siteroot.settings.prod
    static-map = /static=${linkding}/lib/linkding/static
    static-map = /static=${env.LD_DATA_DIR}/favicons
    static-map = /static=${/home/matt/downloads/static}
    processes = 2
    threads = 2
    vacuum = True
    buffer-size = 8192
    die-on-term = true
    mime-file = ${mailcap}/etc/mime.types
  '';

  startScript = writeShellScript "start-linkding" ''
    mkdir -p ${env.LD_DATA_DIR}
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "export ${k}=${lib.escapeShellArg v}") env)}

    cd ${linkding}/lib/linkding

    ${linkding}/bin/linkding migrate
    ${linkding}/bin/linkding enable_wal
    (cd ${env.LD_DATA_DIR} && ${linkding}/bin/linkding generate_secret_key)
    ${linkding}/bin/linkding create_initial_superuser

    ${socat}/bin/socat VSOCK-LISTEN:8080,fork UNIX-CONNECT:/tmp/linkding.sock &
    ${uwsgi'}/bin/uwsgi --http11-socket /tmp/linkding.sock ${uwsgiCfg}
  '';

in

netes.runVM {
  name = "linkding-vm";
  pkg = writeShellScriptBin "linkding-init" ''
    export PATH=${lib.makeBinPath [ busybox ]}

    mount -t proc proc /proc
    mount -t sysfs sysfs /sys
    mount -t tmpfs tmpfs /tmp

    mkdir /tmp/linkding
    mount -t virtiofs data /tmp/linkding

    exec ${startScript}
    # exec ${bashInteractive}/bin/bash
  '';
  mounts = [
    {
      tag = "data";
      path = "/tmp/linkding";
    }
  ];
}
