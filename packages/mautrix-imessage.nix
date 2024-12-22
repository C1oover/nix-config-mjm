{
  lib,
  buildGoModule,
  fetchFromGitHub,
  pkg-config,
  olm,
  libheif,
}:

let
  libheif' = libheif.overrideAttrs {
    version = "1.19.5";
    src = fetchFromGitHub {
      owner = "strukturag";
      repo = "libheif";
      tag = "v1.19.5";
      hash = "sha256-damlKiv5a1qxRr8YGK+WCrOwYet9PI3nHv7hnFErm0I=";
    };
  };
in

buildGoModule {
  name = "mautrix-imessage";
  version = "0-unstable-2024-11-27";

  src = fetchFromGitHub {
    owner = "mautrix";
    repo = "imessage";
    rev = "892f056ea4ffd7e14e19bf7a0de354270ee6b070";
    hash = "sha256-TZ9rh0AX5ECQH+DXoINY9opBID2peEhdRrkUJ5peKg8=";
  };

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [
    libheif'
    olm
  ];

  tags = [ "libheif" ];

  vendorHash = "sha256-tiou4Tzr6VQnJeW0NHDndrZQsdHXMb1OXxijVMlTFJI=";
}
