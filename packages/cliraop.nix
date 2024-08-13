{
  stdenv,
  fetchFromGitHub,
  openssl,
}:

stdenv.mkDerivation {
  pname = "cliraop";
  version = "0-unstable-2024-06-11";

  src = fetchFromGitHub {
    owner = "music-assistant";
    repo = "libraop";
    rev = "88015bb9a987860cba5146291ca2d3bde19dc9c5";
    fetchSubmodules = true;

    hash = "sha256-Atq6O+ggKzMd37M5JVLjouQSEXXK2QfaCBf/CApXVuk=";
  };

  buildFlags = [
    "HOST=linux"
    "PLATFORM=x86_64"
    "STATIC=1"
  ];

  buildInputs = [ openssl ];

  preBuild = ''
    sed -i -e '7s/-s //' Makefile
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp bin/cliraop-linux-x86_64 $out/bin/cliraop

    runHook postInstall
  '';
}
