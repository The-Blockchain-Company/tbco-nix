self: super: let
  # bump mozilla-nixpkgs rev and run:
  # curl https://static.rust-lang.org/dist/channel-rust-stable.toml -o overlays/rust/channel-rust-stable.toml
  # to bump the rust stable version to latest
  stableChannelToml = ./channel-rust-stable.toml;
  stableChannel = super.lib.rustLib.fromManifestFile stableChannelToml {
    inherit (super) stdenv fetchurl patchelf;
  };

in {
  rust.packages.stable.rustc = stableChannel.rust;
  rust.packages.stable.cargo = stableChannel.cargo;
  rustPlatform = super.recurseIntoAttrs (super.rust.makeRustPlatform {
    rustc = stableChannel.rust;
    cargo = stableChannel.cargo;
  });
  makeQuibitous = (super.pkgs.callPackage ./quibitous.nix {}).makeQuibitous;
  makeQcli = (super.pkgs.callPackage ./quibitous.nix {}).makeQcli;
  makeQuibitous-debug = (super.pkgs.callPackage ./quibitous.nix { buildType = "debug"; }).makeQuibitous;
  makeQcli-debug = (super.pkgs.callPackage ./quibitous.nix { buildType = "debug"; }).makeQcli;
  bcc-http-bridge = super.pkgs.callPackage ./bcc-http-bridge.nix {};
  bcc-http-bridge-emurgo = super.pkgs.callPackage ./bcc-http-bridge-emurgo.nix {};
  bcc-cli = super.pkgs.callPackage ./bcc-cli.nix {};
}
