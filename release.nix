let commonLib = (import ./. {}); in
{ system ? builtins.currentSystem
, config ? {}
, pkgs ? commonLib.getPkgs { inherit system config; }

# this is passed in by hydra to provide us with the revision
, tbco-nix ? { outPath = ./.; rev = "abcdef"; }

, scrubJobs ? true
, supportedSystems ? [ "x86_64-linux" "x86_64-darwin" ]
, nixpkgsArgs ? {
    config = config // { allowUnfree = false; inHydra = true; };
  }
}:

with (import (commonLib.nixpkgs + "/pkgs/top-level/release-lib.nix") {
  inherit supportedSystems scrubJobs nixpkgsArgs;
  packageSet = import ./.;
});

with pkgs.lib;

let
  inherit (commonLib) quibitousLib bccLib sources;

  quibitousPackages = foldl' (sum: name:
    recursiveUpdate {
      quibitousLib.environments.${name} = {
        packages = {
          jcli = supportedSystems;
          jcli-debug = supportedSystems;
          quibitous = supportedSystems;
          quibitous-debug = supportedSystems;
        };
      };
    } sum
  ) {} (attrNames quibitousLib.environments);

  usedQuibitousVersions = flatten (mapAttrsToList (name: env:
    with env.packages; [ jcli jcli-debug quibitous quibitous-debug ]
  ) quibitousLib.environments);

  quibitousConfigs = quibitousLib.forEnvironments quibitousLib.mkConfigHydra;

  mappedPkgs = mapTestOn ({
    rust-packages.pkgs.bcc-http-bridge = supportedSystems;
    haskell-nix-extra-packages.stackNixRegenerate = supportedSystems;
    haskell-nix-extra-packages.haskellBuildUtils = supportedSystems;

    # Development tools
  } // quibitousPackages);

in
fix (self: mappedPkgs // {
  inherit (commonLib) check-hydra;
  inherit quibitousConfigs;
  quibitous-deployment = quibitousLib.mkConfigHtml { inherit (quibitousLib.environments) itn_rewards_v1 beta nightly legacy; };
  bcc-deployment = bccLib.mkConfigHtml { inherit (bccLib.environments) mainnet testnet p2p aurum-purple staging sophie_qa sre; };

  forceNewEval = pkgs.writeText "forceNewEval" tbco-nix.rev;
  required = pkgs.lib.hydraJob (pkgs.releaseTools.aggregate {
    name = "required";
    constituents = (with self; [
      self.forceNewEval
      rust-packages.pkgs.bcc-http-bridge.x86_64-linux
      haskell-nix-extra-packages.stackNixRegenerate.x86_64-linux
      haskell-nix-extra-packages.haskellBuildUtils.x86_64-linux
    ]) ++ usedQuibitousVersions;
  });
})
