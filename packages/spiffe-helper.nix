{
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "spiffe-helper";
  version = "0.10.0";

  src = fetchFromGitHub {
    owner = "spiffe";
    repo = "spiffe-helper";
    tag = "v${version}";
    hash = "sha256-nakwTJBE8ICuRCmG+pjh1gZVFIXSOgsxTDjEeBrwufE=";
  };

  preCheck = ''
    patchShebangs pkg/sidecar/sidecar_test.sh
  '';

  vendorHash = "sha256-sAcmJNry3nuWyzt0Ee05JjROR/pDXxu2NVmltotSD0U=";
}
