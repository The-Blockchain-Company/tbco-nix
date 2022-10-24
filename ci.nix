let
  sources = import ./nix/sources.nix;
  nixpkgs = import sources.nixpkgs { };
  tbco-nix = import ./. { };
  inherit (nixpkgs.lib) flatten mapAttrs;

in {
  quibitous = nixpkgs.recurseIntoAttrs (mapAttrs (name: env:
    nixpkgs.recurseIntoAttrs {
      inherit (env.packages) qcli qcli-debug quibitous quibitous-debug;
    }) tbco-nix.quibitousLib.environments);
}
