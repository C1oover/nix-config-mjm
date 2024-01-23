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
          -p EnvironmentFile=/run/agenix/garage.env \
          --wait \
          -qt \
          ${garage}/bin/garage \
          "$@"
      '';
}
