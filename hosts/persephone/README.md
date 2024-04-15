# persephone

This is the configuration for my personal laptop.
It's a 13th generation Intel Framework 13, with 64GB of RAM and 1TB of storage.

## Notes

-   It uses a tmpfs root filesystem, with permanent storage kept under `/persist`.
    For convenience, all of `/home` is persisted.
    At some point, I'd like to make that more fine-grained, but it's a lot of work for questionable benefit, so I haven't done it yet.
-   Because life is boring when computers are too stable, the permanent storage is using [bcachefs](https://bcachefs.org/).
    It's my only machine that's using it.
    It's a single-device filesystem, with native bcachefs encryption (not LUKS) and zstd compression enabled.
-   It uses [Lanzaboote](https://github.com/nix-community/lanzaboote) to do SecureBoot.
    This allows using Clevis to automatically unlock the disk at boot as long as the SecureBoot configuration hasn't been messed with.
-   It runs Plasma 6 ([my desktop environment of choice](../common/global/nixos/desktop/)) with Wayland.
