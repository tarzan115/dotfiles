# Workspace wrapper: copied (not symlinked) into ~/workspace/kotlin/flake.nix
# because nix snapshots path flakes into the store, so an absolute symlink
# flake.nix would dangle. The real shell lives in nix/kotlin-shell.nix and is
# pulled in as a path input, so edits there are picked up live by nix.
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    shells.url = "path:/home/doanh/dotfiles/nix";
    shells.flake = false;
  };

  outputs =
    { self, nixpkgs, shells }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      devShells.${system}.default = import "${shells}/kotlin-shell.nix" { inherit pkgs; };
    };
}