{ substituteAll
, jq
, lib
, coreutils
, time
, gnutar
, gzip
, fetchFromGitHub
}:
let
  rev = "312cb42275e593eea5c44d8430ab09375fdb2fdb";
  hydra-src = fetchFromGitHub {
    inherit rev;
    owner = "The-Blockchain-Company";
    repo = "hydra";
    sha256 = "09jb6lyzkp6pc5c1xrav250v1rcxj9cklmpnc651ays04j0ms6fx";
  };
  hydra = (import "${hydra-src}/release.nix" {
    hydraSrc = {
      outPath = hydra-src;
      rev = builtins.substring 0 6 rev;
      revCount = 1234;
    };
  }).build.x86_64-linux;
  check-hydra = substituteAll {
    src = ./check-hydra.sh;
    tools = lib.makeBinPath [ jq hydra coreutils time gnutar gzip ];
    isExecutable = true;
    postInstall = ''
      patchShebangs $out
    '';
  };
in check-hydra
