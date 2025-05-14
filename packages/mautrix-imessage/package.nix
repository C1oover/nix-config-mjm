{
  buildGoModule,
  fetchFromGitHub,
  pkg-config,
  olm,
  libheif,
}:

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
    libheif
    olm
  ];

  tags = [ "libheif" ];

  vendorHash = "sha256-tiou4Tzr6VQnJeW0NHDndrZQsdHXMb1OXxijVMlTFJI=";
}
