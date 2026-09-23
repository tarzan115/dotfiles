#!/usr/bin/env bash
# Cargo-managed tools: everything NOT in nixpkgs (home.nix covers what nixpkgs
# has; topgrade keeps these fresh). Both machines: NixOS runs this after the
# first `nixos-rebuild switch`, init-macos.sh calls it automatically.
#
# ponytail: leaf's upstream release names defeat binstall's asset guessing, so
# it compiles from source here — fine for a once-per-machine bootstrap.
set -euo pipefail

cargo binstall -y leaf-markdown-viewer presenterm
