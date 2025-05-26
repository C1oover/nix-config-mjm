{
  linux,
  fetchFromGitHub,
  runCommand,
}:

let
  ch-linux = fetchFromGitHub {
    owner = "cloud-hypervisor";
    repo = "linux";
    rev = "87c042ca5da0d12a9cd52c4e6225e20e2884d53f";
    hash = "sha256-N1AXS71t9SxQQ48eS9R+AvVArHJr3qkCa0DjO+cQSIg=";
  };
  config = runCommand "linux-config" { } ''
    cat "${ch-linux}/arch/x86/configs/ch_defconfig" > $out
    echo CONFIG_EROFS_FS=y >> $out
  '';
in

linux.overrideAttrs (_: {
  configfile = config;
})
