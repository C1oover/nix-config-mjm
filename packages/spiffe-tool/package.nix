{ gitignore, buildGoModule }:

buildGoModule {
  pname = "spiffe-tool";
  version = "0.1.0";

  src = gitignore.gitignoreSource ./.;

  vendorHash = "sha256-oxQIfhgvOhnVY460Q56gynIG0Lss0cBGPMOQ/cbgjWM=";
}
