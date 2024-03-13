{
  lib,
  callPackage,
  beamPackages,
  nodePackages,
  nix-gitignore,
  esbuild,
}:
let
  pname = "homelab";
  version = "1.0.0"; # APP VERSION
  src = nix-gitignore.gitignoreSource ''
    /.*
    /README.md
    /flake.*
    /*.nix
  '' ./.;
  mixNixDeps = import ./deps.nix { inherit lib beamPackages; };
  nodeDeps = (callPackage ./assets { }).shell.nodeDependencies;

  tailwind = nodePackages.tailwindcss.overrideAttrs (_oa: {
    plugins = [ nodePackages."@tailwindcss/forms" ];
  });
in
beamPackages.mixRelease {
  inherit
    src
    pname
    version
    mixNixDeps
    ;

  preBuild = ''
    export APP_VERSION="${version}"
  '';

  postBuild = ''
    ln -sf ${nodeDeps}/lib/node_modules assets/node_modules

    mkdir -p jsdeps
    ln -sf ${mixNixDeps.phoenix.src} jsdeps/phoenix
    ln -sf ${mixNixDeps.phoenix_html.src} jsdeps/phoenix_html
    ln -sf ${mixNixDeps.phoenix_live_view.src} jsdeps/phoenix_live_view

    cd assets
    ${tailwind}/bin/tailwind --config=tailwind.config.js --input=css/app.css --output=../priv/static/assets/app.css --minify
    NODE_PATH="../jsdeps" ${esbuild}/bin/esbuild js/app.js --bundle --target=es2017 --outdir=../priv/static/assets '--external:/fonts/*' '--external:/images/*' --minify
    cd ..

    mix do deps.loadpaths --no-deps-check, phx.digest
    mix phx.digest --no-deps-check
  '';

  passthru = {
    inherit esbuild tailwind;
  };
}
