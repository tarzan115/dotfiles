# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mangowm = {
      url = "github:mangowm/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms = {
      url = "github:avengemedia/dankmaterialshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # caps is a git submodule; Nix flakes can't see files inside submodule
    # gitlinks, so pull it in as a local path input instead. Must be
    # absolute: relative path inputs resolve against the flake's store copy.
    caps = {
      url = "path:/home/doanh/dotfiles/caps";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      mangowm,
      dms,
      ...
    } @ inputs: {
      nixosConfigurations.doanh-nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs;};
        modules = [
          mangowm.nixosModules.mango
          dms.nixosModules.dank-material-shell
          home-manager.nixosModules.home-manager
          {
            home-manager.useUserPackages = true;
            home-manager.useGlobalPkgs = true;
            home-manager.users.doanh = import ./home.nix;
          }
          ./configuration.nix
        ];
      };
    };
}
