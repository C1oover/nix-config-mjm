{
  lib,
  netes,
  writeShellScriptBin,
  busybox,
  ghostunnel,
  socat,
}:

netes.runVM {
  name = "ghostunnel-vm";
  pkg = writeShellScriptBin "ghostunnel-init" ''
    export PATH=${
      lib.makeBinPath [
        busybox
        ghostunnel
        socat
      ]
    }
    mount -t proc proc /proc
    mount -t sysfs sysfs /sys
    mount -t tmpfs tmpfs /tmp

    socat VSOCK-LISTEN:443,fork UNIX-CONNECT:/tmp/source.sock &
    socat UNIX-LISTEN:/tmp/target.sock,fork VSOCK-CONNECT:2:80 &

    socat UNIX-LISTEN:/tmp/source.sock,fork UNIX-CONNECT:/tmp/target.sock

    # ghostunnel server \
    #   --listen unix:/tmp/source.sock \
    #   --target unix:/tmp/target.sock \
    #   --cert ${./linkding.lvh.me.pem} \
    #   --key ${./linkding.lvh.me-key.pem} \
    #   --disable-authentication
  '';
}
