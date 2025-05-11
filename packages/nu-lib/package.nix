{
  gitignore,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  name = "nu-lib";
  version = "0.1.0";

  src = gitignore.gitignoreSource ./nu-lib;

  installPhase = ''
    runHook preInstall

    install -v -d $out/share/nu/nu-lib
    install -v -t $out/share/nu/nu-lib *.nu

    runHook postInstall
  '';
}
