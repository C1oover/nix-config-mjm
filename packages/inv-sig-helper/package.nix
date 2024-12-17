{
  oldpkgs,
}:

oldpkgs.inv-sig-helper.overrideAttrs {
  patches = [ ./fix.patch ];
}
