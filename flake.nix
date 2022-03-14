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

  };
}
