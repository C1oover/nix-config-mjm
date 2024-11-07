{
  inputs ? import ../npins,
  pkgs ? import inputs.nixos { config.allowUnfree = true; },
  ...
}@args:
let
  tf = import ../terraform { inherit pkgs; };

  outpkgs = if (args ? outpkgs) then args.outpkgs else pkgs // packages;
  callPackage =
    if (args ? outpkgs) then args.outpkgs.callPackage else pkgs.lib.callPackageWith outpkgs;

  packages = {
    caddy-desec = callPackage ./caddy { };
    cliraop = callPackage ./cliraop.nix { };
    homelab = callPackage ../apps/homelab/package.nix { };
    host-scripts = callPackage ../hosts/scripts { };
    linkding = callPackage ./linkding.nix { };
    mautrix-slack = callPackage ./mautrix-slack.nix { };
    nu-lib = callPackage ./nu-lib { };
    nvd-json = callPackage ../apps/nvd-json/package.nix { };
    pragmata-pro = callPackage ./pragmata-pro.nix { };
    scripts = callPackage ../scripts { };
    tofu-scripts = callPackage ../terraform/scripts {
      inherit (tf) opentofu terraformConfiguration;
    };
    writeNu = callPackage ./nu-lib/writer.nix { };
    writeNuBin = callPackage ({ writeNu }: name: writeNu "/bin/${name}") { };

    music-assistant =
      (pkgs.music-assistant.overrideAttrs (oldAttrs: {
        preBuild = ''
          ln -sf ${outpkgs.cliraop}/bin/cliraop music_assistant/server/providers/airplay/bin/cliraop-linux-x86_64
        '';
        patches = oldAttrs.patches ++ [ ./ma-no-install.patch ];
      })).override
        { python3 = outpkgs.python3; };
    vault = pkgs.vault-bin;

    pythonPackagesExtensions = pkgs.pythonPackagesExtensions ++ [
      (pythonFinal: pythonPrev: {
        py-opensonic = pythonPrev.py-opensonic.overridePythonAttrs {
          version = "5.2.1";
          src = pkgs.fetchFromGitHub {
            owner = "khers";
            repo = "py-opensonic";
            rev = "v5.2.1";
            hash = "sha256-lVErs5f2LoCrMNr+f8Bm2Q6xQRNuisloqyRHchYTukk=";
          };
        };
      })
    ];
  };
in
packages
