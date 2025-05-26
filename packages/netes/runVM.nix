{
  lib,
  writeShellScriptBin,
  cloud-hypervisor,
  virtiofsd,
  linux,
  netes,
}:

{
  name,
  pkg,
  memory ? 256,
  useHugepages ? true,
  useSerial ? true,
  useVsock ? true,
  mounts ? [ ],
}:

let
  rootImage = netes.makeClosureImage {
    name = "${name}-root.erofs";
    paths = [ pkg ];
  };

  kernel = linux.override {
    autoModules = false;
    ignoreConfigErrors = true;
    kernelPatches = [
      {
        name = "libnvdimm";
        patch = ./kernel.patch;
      }
    ];
    structuredExtraConfig = with lib.kernel; {
      ACPI_NFIT = yes;
      EROFS_FS = yes;
      LIBNVDIMM = yes;
      VIRTIO = yes;
      VIRTIO_BALLOON = yes;
      VIRTIO_BLK = yes;
      VIRTIO_FS = yes;
      VIRTIO_NET = yes;
      VIRTIO_PCI = yes;
      VIRTIO_PMEM = yes;
      VIRTIO_VSOCKETS = yes;
      VIRTIO_VSOCKETS_COMMON = yes;
      VSOCKETS = yes;
      VSOCKETS_DIAG = yes;
      VSOCKETS_LOOPBACK = yes;
      BLK_DEV_PMEM = yes;
      BLK_DEV_RAM = yes;
      DAX = yes;
      FS_DAX = yes;
      FUSE_FS = yes;
      FUSE_DAX = yes;
      X86_PMEM_LEGACY = yes;
      PHYSICAL_ALIGN = freeform "0x1000000";
      RANDOMIZE_MEMORY_PHYSICAL_PADDING = freeform "0xa";
    };
  };
in

writeShellScriptBin name ''
  # kill the whole process group when exiting
  trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

  runtime_dir="/run/yci/${name}"
  rm -rf "$runtime_dir"
  mkdir -p "$runtime_dir"
  cd "$runtime_dir"

  ${lib.concatMapStrings (m: ''
    ${virtiofsd}/bin/virtiofsd \
      --socket-path ${m.tag}.sock \
      --shared-dir ${m.path} \
      --thread-pool-size 8 \
      --posix-acl \
      --xattr &
  '') mounts}

  ${cloud-hypervisor}/bin/cloud-hypervisor \
    --kernel ${kernel}/bzImage \
    --pmem file=${rootImage},discard_writes=on \
    --cmdline "console=ttyS0 loglevel=8 root=/dev/pmem0 rootflags=dax=always init=${lib.getExe pkg} ro" \
    ${lib.optionalString useSerial "--serial tty --console off"} \
    ${lib.optionalString useVsock "--vsock cid=3,socket=vsock.sock"} \
    ${
      lib.concatMapStringsSep " " (
        m: "--fs tag=${m.tag},socket=${m.tag}.sock,num_queues=1,queue_size=512"
      ) mounts
    } \
    --cpus boot=1 \
    --memory size=${toString memory}M,shared=on${lib.optionalString useHugepages ",hugepages=on"}
''
