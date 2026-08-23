# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Pinned older branch: xdg-desktop-portal-wlr 0.8.x fails to capture on
    # mango ("ext: started frame without buffer", see emersion/xdwim#369),
    # while 0.7.x (last shipped in nixos-25.05) uses the stable
    # wlr-screencopy protocol and works. Overlayed in configuration.nix.
    nixpkgs-old.url = "github:NixOS/nixpkgs/nixos-25.05";

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

    # tuigreet config folder — pulled in as a path input so configuration.nix
    # can reference its files in pure evaluation mode.
    tuigreet-config = {
      url = "path:/home/doanh/dotfiles/tuigreet";
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
