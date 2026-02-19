{
  description = "Example home-manager configuration for shep-home";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }: let
    system = "x86_64-linux";
    pkgs   = nixpkgs.legacyPackages.${system};
    # Username is resolved at activation time from the environment.
    username = builtins.getEnv "USER";
  in {
    homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [ ./home.nix ];
      extraSpecialArgs = { inherit username; };
    };
  };
}
