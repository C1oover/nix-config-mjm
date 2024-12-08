{
  lib,
  writeNuBin,
  npins,
  git,
}:

writeNuBin "scripts" {
  makeWrapperArgs = [
    "--prefix"
    "PATH"
    ":"
    "${lib.makeBinPath [
      npins
      git
    ]}"
  ];
} ./scripts.nu
