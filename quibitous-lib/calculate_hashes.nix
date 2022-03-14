{ version, sha256, cargoSha256 }@args:
let
  inherit (import ../. { }) quibitousLib;
  inherit (quibitousLib) makeJcli;
  common = f: f (makeJcli args);
in {
  src = (makeJcli args).src;
  cargoDeps = (makeJcli args).cargoDeps;
}
