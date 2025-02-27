# Host configurations

This is where the configs for each of my systems (both NixOS and nix-darwin) lives.
Each system has its own directory with at minimum a `default.nix`.
Some may have a `home.nix` which contains any Home Manager settings specific to that system.
The `home.nix` is [automatically imported](../modules/common/base/user.nix#L27) as a Home Manager module if present.

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
  - [melinoe](melinoe/): GitLab server
  - [hypnos](hypnos/): GitLab CI runner
- Raspberry Pi 4B's
  - [arges](arges/): NUT server, remote builder for aarch64 in CI
  - [brontes](brontes/), [steropes](steropes/): Ingress reverse proxy with Caddy for all self-hosted services
- VPS
  - [aion](aion/): a super barebones Hetzner VM that serves as a public IPv4 proxy to brontes and steropes

## Deploying changes

Every half hour, [a CI job](../.gitlab-ci.yml#L64) runs that [checks for updates](../packages/scripts/scripts.nu) in either the `nixos`, `nixos-small` or `nixpkgs` (for Darwin) npins sources, which target the various unstable channels.
If any of these channels has updates, then all pinned sources are updated, and the updated sources are committed by the CI job.

Each commit (including the automatic source updates) to the `main` branch will trigger a deploy job to all NixOS servers.
Deploys are done with a bespoke deployment tool called [dippy](../packages/dippy).
The deploy plan configuration can be found in [plans.nix](../plans.nix).

Workstations are updated manually, still using `dippy`.
By running `just rebuild`, it will build the configuration for the current system with [nom](https://github.com/maralorn/nix-output-monitor), and then use [nvd](https://gitlab.com/khumba/nvd) to print which package versions were changed.
Then it will check if the kernel or systemd versions have changed, and will decide whether the changes should be applied in-place or by rebooting.
Either way, it will prompt for confirmation and then apply the changes.

