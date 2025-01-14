{
  oldpkgs,
}:

oldpkgs.opentofu.withPlugins (p: [
  p.vault
  (p.mkProvider {
    owner = "Valodim";
    repo = "terraform-provider-desec";
    rev = "v0.5.0";
    spdx = "MIT";
    hash = "sha256-t+hpNI1Id8DrtQWuDj9OSdKkKMo/b1O2ViCSXjDxSlQ=";
    vendorHash = "sha256-Dcs1R3smMIRnjiGpt6ML1lsfYYl4ne8gK+BwDravhVI=";
    homepage = "registry.opentofu.org/Valodim/desec";
  })
])
