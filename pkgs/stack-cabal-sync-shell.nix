{ stdenv, bcc-repo-tool }:

stdenv.mkDerivation {
  name = "stack-cabal-sync-shell";
  buildInputs = [ bcc-repo-tool ];
  shellHook = ''
    for EXE in bcc-repo-tool; do
      source <($EXE --bash-completion-script `type -p $EXE`)
    done
  '';
  phases = ["nobuildPhase"];
  nobuildPhase = "mkdir -p $out";
}
