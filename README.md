# TBCO Common Nix Code

[![Build status](https://badge.buildkite.com/e5b12d0fd507084fbdb1849da2de467f1de66b3e5c6d954554.svg)](https://buildkite.com/The-Blockchain-Company/tbco-nix)

This repo contains build code and tools shared between TBCO projects.

1. Pinned versions of [The-Blockchain-Company/nixpkgs](https://github.com/The-Blockchain-Company/nixpkgs).
2. Scripts for regenerating code with `nix-tools`.
3. Some util functions such as source filtering or helpers for [Haskell.nix](https://github.com/The-Blockchain-Company/haskell.nix).
4. Nix builds of development tools such as cache-s3.
5. Nix packages and overlay for the [rust-bcc](https://github.com/The-Blockchain-Company/rust-bcc)
   projects.


## How to use in your project

See [new project skeleton](https://github.com/The-Blockchain-Company/bcc-skeleton/).

## When making changes to `tbco-nix`

Please document any change that might affect project builds in the
[ChangeLog](./changelog.md). For example:

 - Bumping `nixpkgs` to a different branch.
 - Changing API (renaming attributes, changing function parameters, etc).

Also update the [`skeleton`](https://github.com/The-Blockchain-Company/bcc-skeleton/) project if necessary.
