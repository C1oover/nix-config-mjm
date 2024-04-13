# MJ's Nix configuration

Hi, I'm MJ (@mjm:midna.dev on Matrix), and this is my Nix config repo.
It holds all the code to provision the various servers and workstations I use.
It's public both for my own convenience and because it allows others to use it as a resource.
I'm not sure if I'm always a good person to copy from, but if you want to, you certainly can.

## Background

When I first created this repo, I used [Misterio77's nix-config](https://m7.rs/git/nix-config/) as my inspiration.
You'll probably see some similarities in structure to what he uses.
However, it's also probably drifted quite a bit into doing things my own way.
Anyway, thanks Gabriel for the helpful inspiration!

## Repo structure

- [hosts](hosts/): NixOS/nix-darwin configurations for each host
- [home](home/): Home Manager configuration
- [services](services/): Modules for setting up NixOS services, which can be enabled in individual host configs
- [terraform](terraform/): OpenTofu config generated with Terranix (kind of)
- [modules](modules/): Custom modules for extending various things that use the NixOS module system
- [packages](packages/): Nix packages that for whatever reason aren't upstreamed to Nixpkgs

See the READMEs for individual directories for more details.

I use [flake-parts](https://flake.parts) to keep things organized.
A few of the above directories have a `default.nix` that is a flake module,
which adds outputs to the flake that are relevant to that part of the repo.
