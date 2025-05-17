{ gitignore, buildGoModule }:

buildGoModule {
  pname = "spiffe-tool";
  version = "0.1.0";

  src = gitignore.gitignoreSource ./.;

  vendorHash = "sha256-xR/9sgNBgnWw/AjxAciV+mmy6UgHtmAF7fP+ec2LqD0=";
}
