let
  homelabCA = builtins.fetchurl "http://vault.service.consul:8200/v1/pki-homelab/ca/pem";
in
{
  environment.etc."ssl/homelab.pem".source = homelabCA;
  security.pki.certificateFiles = [ homelabCA ];
}
