{
  lib,
  netes,
  hello,
  libndctl,
  util-linux,
  pkgsStatic,
  file,
  bashInteractive,
  python3,
  fish,
  writeShellScriptBin,
}:

netes.runVM {
  name = "hello-vm";
  pkg = writeShellScriptBin "run-hello" ''
    ${hello}/bin/hello

    export PATH=${
      lib.makeBinPath [
        util-linux
        file
        libndctl
        python3
        fish
        bashInteractive
        pkgsStatic.busybox
      ]
    }

    mount -t proc proc /proc
    mount -t sysfs sysfs /sys

    setsid -c -w ${bashInteractive}/bin/bash
  '';
}

GET / HTTP/1.1
Host: linkding



