# shep-home

A devcontainer feature that installs [Nix](https://nixos.org/) (single-user) and applies a [home-manager](https://github.com/nix-community/home-manager) flake configuration inside your devcontainer. Use it to bring your dotfiles, shell aliases, and favourite tools into any container.

## Usage

Add `shep-home` (and `user-sync`, which it depends on) to your `devcontainer.json`:

```json
{
  "image": "debian:trixie-slim",
  "features": {
    "ghcr.io/thetanil/shep-home/user-sync:1": {},
    "ghcr.io/thetanil/shep-home/shep-home:1": {
      "configUrl": "https://github.com/yourname/your-home-config"
    }
  },
  "remoteUser": "${localEnv:USER}",
  "updateContainerUserID": true
}
```

`configUrl` is the HTTPS clone URL of a Git repository containing your home-manager flake. Omit it (or set it to `"bundled"`) to use the built-in example config.

## Creating your own home-manager config repo

1. **Create a new private GitHub repository** (e.g. `your-home-config`). It can be private — the feature clones it at image build time using whatever credentials are available in your build environment.

2. **Add a `flake.nix`** at the root. The key requirement is that `builtins.getEnv "USER"` is used to derive the username so the config works for any user without hardcoding. Use this as your starting point — it mirrors the [bundled example](https://github.com/thetanil/shep-home/blob/219b83141565d906f72dcfa313c6e3352e3dc711/src/shep-home/example/home.nix#L16):

   ```nix
   {
     description = "My home-manager configuration";

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
       username = builtins.getEnv "USER";
     in {
       homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
         inherit pkgs;
         modules = [ ./home.nix ];
         extraSpecialArgs = { inherit username; };
       };
     };
   }
   ```

3. **Add a `home.nix`** next to `flake.nix`. This is where you declare your packages, programs, and dotfiles:

   ```nix
   { config, pkgs, username, ... }: {
     home.username = username;
     home.homeDirectory = "/home/${username}";
     home.stateVersion = "24.11";

     home.packages = with pkgs; [
       ripgrep
       fd
       jq
       htop
     ];

     programs.bash = {
       enable = true;
       shellAliases = {
         ll = "ls -lah";
       };
     };

     programs.git = {
       enable = true;
       userName = "Your Name";
       userEmail = "you@example.com";
     };

     programs.home-manager.enable = true;
   }
   ```

4. **Point `configUrl` at your repo** in `devcontainer.json` as shown above.

Any packages or configuration you declare in `home.nix` will be available in the container after the image builds. Refer to the [home-manager options reference](https://nix-community.github.io/home-manager/options.xhtml) for the full list of things you can configure.
