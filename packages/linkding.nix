{
  python3,
  python3Packages,
  fetchFromGitHub,
  buildNpmPackage,
}:
let
  pname = "linkding";
  version = "1.27.1";
  src = fetchFromGitHub {
    owner = "sissbruecker";
    repo = "linkding";
    rev = "refs/tags/v${version}";
    hash = "sha256-rAIdZuxNzma0lYYoDHrX4NtEnSNmlUaEO+qUCNCcT1A=";
  };

  frontend = buildNpmPackage {
    pname = "linkding-frontend";
    inherit version src;

    npmDepsHash = "sha256-s+ZbAL+t+ABvrA3XXPSjlNmRZrwlWI4x9La2YByBI90=";

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/linkding-ui
      mv bookmarks/static/bundle.js{,.map} $out/lib/linkding-ui/
      cp -r node_modules/spectre.css/src $out/lib/linkding-ui/spectre.css
      runHook postInstall
    '';
  };

  python = python3;
  confusable-homoglyphs = python3Packages.callPackage ./confusable-homoglyphs.nix { };
  django-registration = python3Packages.callPackage ./django-registration.nix {
    inherit confusable-homoglyphs;
  };
  django-sass-processor = python3Packages.callPackage ./django-sass-processor.nix { };
  mozilla-django-oidc = python3Packages.callPackage ./mozilla-django-oidc.nix { };
  waybackpy = python3Packages.callPackage ./waybackpy.nix { };
in
python3Packages.buildPythonApplication rec {
  inherit pname version src;

  format = "other";

  propagatedBuildInputs = with python3Packages; [
    beautifulsoup4
    bleach
    bleach-allowlist
    charset-normalizer
    django
    django-registration
    django-sass-processor
    django-widget-tweaks
    djangorestframework
    huey
    markdown
    mozilla-django-oidc
    psycopg2
    python-dateutil
    requests
    supervisor
    waybackpy
  ];

  preBuild = ''
    rm Makefile siteroot/settings/dev.py
    sed -i 's|../../node_modules/spectre.css/src|${frontend}/lib/linkding-ui/spectre.css|g' bookmarks/styles/spectre.scss
    sed -i -e '19i DATA_DIR = os.getenv("LD_DATA_DIR", "/var/lib/linkding")' -e 's/BASE_DIR, "data",/DATA_DIR,/' siteroot/settings/base.py
    sed -i -e 's/BASE_DIR, "data",/DATA_DIR,/' siteroot/settings/prod.py
    sed -i -e 's/"data", "secretkey.txt"/"secretkey.txt"/' bookmarks/management/commands/generate_secret_key.py
    export LD_DATA_DIR=$(mktemp -d)
  '';

  postBuild = ''
    ${python.pythonOnBuildForHost.interpreter} -OO -m compileall .
    ${python.pythonOnBuildForHost.interpreter} manage.py compilescss
    ${python.pythonOnBuildForHost.interpreter} manage.py collectstatic --clear --no-input '--ignore=*.scss'
    ${python.pythonOnBuildForHost.interpreter} manage.py compilescss --delete-files
  '';

  installPhase =
    let
      pythonPath = python3Packages.makePythonPath propagatedBuildInputs;
    in
    ''
      mkdir -p $out/lib/linkding
      cp -r {bookmarks,siteroot,static,LICENSE.txt,manage.py,version.txt} $out/lib/linkding
      cp ${frontend}/lib/linkding-ui/bundle.js{,.map} $out/lib/linkding/static/
      chmod +x $out/lib/linkding/manage.py
      makeWrapper $out/lib/linkding/manage.py $out/bin/linkding \
        --prefix PYTHONPATH : ${pythonPath}
    '';

  passthru = {
    inherit python frontend;
  };
}
