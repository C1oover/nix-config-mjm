{
  oldpkgs,
  fetchFromGitHub,
  rustPlatform,
}:

oldpkgs.inv-sig-helper.overrideAttrs (oldAttrs: rec {
  src = fetchFromGitHub {
    owner = "mjm";
    repo = "inv_sig_helper";
    rev = "1627e1b757fdc691285786456d1dc83d6049e6e8";
    hash = "sha256-cQXWo+idyfFeJ2nnT8HKgjCd0Htc4pOE6aODsl3sf/8=";
  };

  cargoDeps = rustPlatform.fetchCargoVendor {
    name = oldpkgs.inv-sig-helper.name;
    inherit src;
    hash = "sha256-DnJL7kkcVn5dW3AoPCn829WmkaCjpDZtYUXnpiB857Q=";
  };
})
