{ version, sha256, cargoSha256 }@args:
let
  inherit (import ../. { }) quibitousLib;
  inherit (quibitousLib) makeQcli;
  common = f: f (makeQcli args);
in {
  src = (makeQcli args).src;
  cargoDeps = (makeQcli args).cargoDeps;
}
