{ oldpkgs }:

oldpkgs.peertube.overrideAttrs {
  dontCheckForBrokenSymlinks = true;
}
