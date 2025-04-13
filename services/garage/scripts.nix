{
  bash,
  resholve,
  garage,
  systemd,
}:
let
  interpreter = "${bash}/bin/bash";
in
{
  # Add a `g` command to the path that runs garage with the RPC secret
  # so it's convenient to manage the cluster.
  g =
    resholve.writeScriptBin "g"
      {
        inherit interpreter;
        inputs = [
          systemd
          garage
        ];
        # it definitely can, so we pre-resolve this
        execer = [ "cannot:${systemd}/bin/systemd-run" ];
        keep = "${garage}/bin/garage";
      }
      ''
        systemd-run \
          --service-type=oneshot \
          -p LoadCredential=garage_rpc_secret:/run/garage-creds.sock \
          --wait \
          -qt \
          --collect \
          env 'GARAGE_RPC_SECRET_FILE=''${CREDENTIALS_DIRECTORY}/garage_rpc_secret' \
          ${garage}/bin/garage \
          "$@"
      '';
}
