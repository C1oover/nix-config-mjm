let
  homelabCA = import ../../../lib/vault/ca.nix;
in {
  environment.etc."ssl/homelab.pem".source = homelabCA;
  security.pki.certificateFiles = [homelabCA];
}
