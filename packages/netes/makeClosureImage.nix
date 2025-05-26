{
  stdenv,
  closureInfo,
  erofs-utils,
  qemu,
}:

{
  name,
  paths,
}:

stdenv.mkDerivation {
  inherit name;

  dontUnpack = true;

  # TODO use disallowedRequisites

  nativeBuildInputs = [
    erofs-utils
    qemu
  ];

  buildPhase = ''
    runHook preBuild

    baseRoot=$(mktemp -d)
    mkdir $baseRoot/dev $baseRoot/sys $baseRoot/proc $baseRoot/tmp

    tar --create \
      --absolute-names \
      --verbatim-files-from \
      --transform "s|$baseRoot||" \
      --files-from ${closureInfo { rootPaths = paths; }}/store-paths \
      --add-file=$baseRoot/dev \
      --add-file=$baseRoot/sys \
      --add-file=$baseRoot/proc \
      --add-file=$baseRoot/tmp \
    | mkfs.erofs \
      --force-uid=0 \
      --force-gid=0 \
      -U ca4cbc25-1a58-4532-871d-53b248474de0 \
      -T 0 \
      --tar=f \
      "$out"

    # pmem requires multiples of 2M
    truncate --size=%2M "$out"

    runHook postBuild
  '';
}
