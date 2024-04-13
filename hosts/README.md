# Host configurations

This is where the configs for each of my systems lives.
Each system has its own directory with at minimum a `default.nix`

## Hosts

- Workstations
  - [persephone](persephone/): 13th gen Intel Framework 13 laptop
  - [uranus](uranus/): Desktop/gaming PC built in 2022
  - [athena](athena/): Work 16-inch MacBook Pro M2
- Proxmox VMs, all running on a cluster of 3 Proxmox VE hosts built from various Dell OptiPlex SFF machines I bought on craigslist
  - [megaera](megaera/), [tisiphone](tisiphone/), [alecto](alecto/): 3 node Consul and Vault cluster
  - [leto](leto/): Runs majority of my self-hosted services
  - [chaos](chaos/): Media server
  - [helio](helios/): Matrix homeserver and various bridges
  - [hypnos](hypnos/): GitLab CI runner
- Proxmox LXC containers, which are a bad idea (with NixOS at least) that I don't recommend:
  - [rhea](rhea/), [cronus](cronus/): DNS servers
- Raspberry Pi 4B's
  - [arges](arges/): NUT server, remote builder for aarch64 in CI
  - [brontes](brontes/), [steropes](steropes/): Ingress reverse proxy with Nginx for all self-hosted services

## Deploying changes

Every hour, a CI job runs that checks for updates in either the `nixos` or `nixpkgs` (for Darwin) flake inputs, which target `nixos-unstable` and `nixpkgs-unstable` respectively.
If either channel has updates, then all flake inputs are updated, and the updated lock file is committed by the CI job.

Each commit (including the automatic lock file updates) to the `main` branch will trigger a deploy job to all NixOS servers.
Deploys are done with [Colmena](https://github.com/zhaofengli/colmena).
The hive configuration for Colmena can be found in [default.nix](./default.nix).

Workstations are updated by hand.
Updating a workstation is done in two steps:

1.  `just rebuild`: Builds configuration for the current system with [nom](https://github.com/maralorn/nix-output-monitor),
    and uses [nvd](https://gitlab.com/khumba/nvd) to print which package versions were changed.
2.  `just switch`: Switch to the newly-built configuration.
    This is done with a small script that skips rebuilding (more importantly, reevaluating), as it assumes `just rebuild` was already run.
    If the kernel, systemd, or DE have been updated, I'll likely run `just boot` to switch on reboot.

