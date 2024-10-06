{
  lib,
  writers,
  nushell,
  nu-lib,
}:
name: argsOrScript:
let
  interpreter = "${lib.getExe nushell} --no-config-file --include-path ${nu-lib}/share/nu";
in
if lib.isAttrs argsOrScript && !lib.isDerivation argsOrScript then
  writers.makeScriptWriter (argsOrScript // { inherit interpreter; }) name
else
  writers.makeScriptWriter { inherit interpreter; } name argsOrScript
