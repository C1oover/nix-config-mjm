# Host configurations

This is where the configs for each of my systems (both NixOS and nix-darwin) lives.
Each system has its own directory with at minimum a `default.nix`.
Some may have a `home.nix` which contains any Home Manager settings specific to that system.
The `home.nix` is [automatically imported](../modules/common/base/user.nix#L27) as a Home Manager module if present.

## Hosts

- Workstations
  - [persephone](persephone/): 13th gen Intel Framework 13 laptop

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

