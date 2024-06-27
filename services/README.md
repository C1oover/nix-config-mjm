# Service modules

This directory contains NixOS modules for configuring various self-hosted services I run on my machines.

Each module directory contains a `default.nix` file.
Similar to the built-in NixOS modules, all of these modules are imported unconditionally on all NixOS machines.
They do nothing unless the corresponding `enable` option is set to `true`.
For instance, `services/foo/default.nix` will define a `mjm.foo.enable` option and only configure the service if it is set to `true`.
Services can define other options under that namespace as well for further customization.

These modules are much more opinionated than those in upstream NixOS.
They're specifically configured to serve my own needs.

## Ingress and OpenTofu provisioning

Services can also define things that affect state outside just the host running the service, things like:

- Ingress (nginx) reverse-proxy vhost configuration
- Anything that needs to be provisioned with OpenTofu, primarily Vault approles and policies

The [ingress](ingress/) service will use the `nodes` parameter Colmena provides to get all of the vhost configuration from all the nodes and merge them together.
It will then use that to generate the nginx configuration.
Similarly, when creating the OpenTofu configuration, OpenTofu resources and Vault services and policies are merged together to produce the full configuration.

The [Vault support](../terraform/vault.nix) is particularly nice, as it's smart about assigning policies to the hosts running the corresponding services, without having to explicitly declare which hosts those are.

## State and impermanence

All of my servers are set up with a tmpfs root filesystem, using [Impermanence](https://github.com/nix-community/impermanence) to persist important state.
I have some special options under [`mjm.state`](../hosts/common/global/nixos/impermanence.nix) that allow for declaring files and directories that needs persisting without needing to know the root directory of the persistent storage.
This is important because not all of my machines keep the persisted data in the same place.
Some use `/persist`, some use `/nix/persist`, just because of the ad-hoc way I set them up.

My services can add their data directories to `mjm.state.directories` when the service is enabled, and these directories will end up persisted to whatever `mjm.state.persistDir` is configured as for that machine.
This is way nicer than having a list of all the persisted directories for each host: if I enable a service on a new host, I can't forget to start persisting its data, because it's configured as part of the service.

## Deployment tags

Each service module adds a tag `svc-<name>` to the host's Colmena deployment configuration.
This means that if I want to deploy every machine running a particular service (because I just changed something about it), I can easily do that.
For instance, if I wanted to deploy every machine running garage, I could run:

```
$ just deploy @svc-garage
```
