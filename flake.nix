{
  description = "TBCO nix lib, packages and overlays";

  outputs = { self, nixpkgs }: {
    
    lib = import ./lib nixpkgs.lib;

    overlays = {
      crypto = import ./overlays/crypto;
      haskell-nix-extra = import ./overlays/haskell-nix-extra;
      bcc-lib = (final: prev: {
        bccLib = final.callPackage ./bcc-lib {};
      });
      utils = import ./overlays/utils;
    }; 
    
    cabal-wrapper = ./pkgs/cabal-wrapper.nix;

    checks = {
      hlint = ./tests/hlint.nix;
      shell = ./tests/shellcheck.nix;
      stylish-haskell = ./tests/stylish-haskell.nix;
    };
      
    utils = {
      cabal-project = ./ci/cabal-project-regenerate;
      ciJobsAggregates = ./ci/aggregates.nix;
    };

  };
}
