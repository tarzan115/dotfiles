# Workspace wrapper: rendered (not symlinked) into ~/workspace/rust/flake.nix
# because nix snapshots path flakes into the store, so an absolute symlink
# flake.nix would dangle. The real shell lives in nix/rust-shell.nix and is
# pulled in as a path input, so edits there are picked up live by nix.
#
# @DOTFILES@ is substituted with the real dotfiles path by the
# workspaceFlakes activation in home.nix (flake inputs can't use ~ or $HOME).
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    shells.url = "path:@DOTFILES@/nix";
    shells.flake = false;
  };

  outputs =
    { self, nixpkgs, fenix, shells }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system}.extend fenix.overlays.default;
    in
    {
      devShells.${system}.default = import "${shells}/rust-shell.nix" { inherit pkgs; };
    };
}