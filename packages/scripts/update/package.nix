{
  lib,
  writeNuBin,
  npins,
  git,
}:

writeNuBin ",update" {
  makeWrapperArgs = [
    "--prefix"
    "PATH"
    ":"
    "${lib.makeBinPath [
      npins
      git
    ]}"
  ];
} ./update.nu
