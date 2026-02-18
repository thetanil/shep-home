{
  description = "Example Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixpkgs/nixpkgs/nixos-25.11";  # Pinned to LTS version 25.11
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }: {
    homeConfigurations = {
      # Replace 'vscode' with your username or keep it as default for devcontainers
      vscode = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [ ./home.nix ];
      };
    };
  };
}
