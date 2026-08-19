#!/usr/bin/env bash
# Update all flake inputs (nixpkgs, home-manager, mangowm, dms).
# Run `nixos-rebuild switch` afterwards to apply.
set -euo pipefail
cd ~/dotfiles/nixos
nix --extra-experimental-features "nix-command flakes" flake update
