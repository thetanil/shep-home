# shep-home

Personalize shep containers with your own home-manager configuration.

## Overview

This repository provides two devcontainer features for setting up personalized development environments:

1. **user-sync**: Creates a user matching the host user for seamless file permissions
2. **home-manager**: Installs Nix and home-manager, allowing you to bring your personal home directory configuration to any devcontainer

Your configuration is kept in a private git repository and applied on container startup.

## Features

- **User Synchronization**: Automatically creates a user with UID 1000 matching your host user
- **Private Configuration**: Keep your home environment configuration in a private git repository
- **Nix Flakes Support**: Use modern Nix flakes for declarative configuration
- **Persistent Cache**: Nix cache is mounted at `/cache` and shared across container instances
- **CLI-Only**: home-manager runs as a CLI tool (no daemon) to configure and exit
- **First-Startup Configuration**: Configuration is applied when the container is created, not at build time
- **Authentication Support**: Works with private repositories requiring authentication

## Usage

### 1. Add the features to your devcontainer.json

It's recommended to use both features together for proper user and home directory setup:

```json
{
  "name": "My Dev Container",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/thetanil/shep-home/user-sync:1": {
      "username": "vscode"
    },
    "ghcr.io/thetanil/shep-home/home-manager:1": {}
  },
  "containerEnv": {
    "HOME_MANAGER_GIT_URL": "https://github.com/yourusername/your-home-config.git"
  },
  "remoteUser": "vscode"
}
```

**Note**: The `user-sync` feature should be listed before `home-manager` to ensure the user exists before home-manager runs.

### 2. Set up your home-manager repository

Your repository should contain a Nix flake with home-manager configuration. Example structure:

```
your-home-config/
├── flake.nix
├── flake.lock
└── home.nix (or other configuration files)
```

Example `flake.nix`:

```nix
{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixpkgs/nixpkgs/nixos-25.11";  # Pinned to LTS version 25.11
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }: {
    homeConfigurations = {
      # Replace with your username (or use your container username)
      myuser = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [ ./home.nix ];
      };
    };
  };
}
```

Example `home.nix`:

```nix
{ config, pkgs, ... }:

{
  # Note: username and homeDirectory are typically set dynamically from the container environment
  home.username = "myuser";  # Will match your container username
  home.homeDirectory = "/home/myuser";  # Will match your container home directory
  home.stateVersion = "25.11";

  programs.git = {
    enable = true;
    userName = "Your Name";
    userEmail = "your.email@example.com";
  };

  programs.zsh = {
    enable = true;
    # Your zsh configuration
  };

  home.packages = with pkgs; [
    ripgrep
    fd
    # Add your favorite tools
  ];
}
```

### 3. Authentication for Private Repositories

For private repositories, you have several options:

#### Option A: SSH Keys
```json
{
  "containerEnv": {
    "HOME_MANAGER_GIT_URL": "git@github.com:yourusername/your-home-config.git"
  },
  "mounts": [
    "source=${localEnv:HOME}/.ssh,target=/home/vscode/.ssh,type=bind,consistency=cached"
  ]
}
```

#### Option B: Personal Access Token
```json
{
  "containerEnv": {
    "HOME_MANAGER_GIT_URL": "https://${localEnv:GITHUB_TOKEN}@github.com/yourusername/your-home-config.git"
  }
}
```

#### Option C: Git Credential Helper
Mount your git credentials into the container:
```json
{
  "mounts": [
    "source=${localEnv:HOME}/.gitconfig,target=/home/vscode/.gitconfig,type=bind,consistency=cached",
    "source=${localEnv:HOME}/.git-credentials,target=/home/vscode/.git-credentials,type=bind,consistency=cached"
  ]
}
```

## How It Works

1. **Build Time**: The `install.sh` script runs during container build and installs:
   - Nix package manager
   - home-manager CLI tool
   - Configures Nix to use `/cache` volume for shared caching

2. **First Startup**: The `home-manager-setup.sh` script runs via `onCreateCommand`:
   - Reads `HOME_MANAGER_GIT_URL` environment variable
   - Clones your private repository to `~/.config/home-manager`
   - Runs `home-manager switch` to apply your configuration
   - Exits (no daemon process)

3. **Subsequent Starts**: Your configuration persists in the container

## Environment Variables

- `HOME_MANAGER_GIT_URL` (required): Git URL to your home-manager configuration repository
- `NIX_CONF_DIR`: Nix configuration directory (default: `/etc/nix`)

## Volume Mounts

- `/cache`: Nix cache volume (automatically created and managed)
  - Shared across all containers using this feature
  - Speeds up package installations

## Options

### user-sync Feature

The user-sync feature supports the following options:

```json
{
  "features": {
    "ghcr.io/thetanil/shep-home/user-sync:1": {
      "username": "vscode"
    }
  }
}
```

- `username`: The username to create in the container (default: "devuser"). This should match your intended remote user.

### home-manager Feature

The home-manager feature supports the following options in `devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/thetanil/shep-home/home-manager:1": {
      "nixVersion": "25.11"
    }
  }
}
```

- `nixVersion`: Version of Nix and home-manager to install (default: "25.11" - the current LTS version). You can also use "latest" for the most recent version, but LTS is recommended for stability.

## Troubleshooting

### Repository not cloning
- Verify `HOME_MANAGER_GIT_URL` is correct
- Check authentication is properly configured
- Ensure the repository is accessible from the container

### home-manager switch fails
- Verify your `flake.nix` or `home.nix` is valid
- Check the home-manager logs for specific errors
- Ensure your configuration is compatible with the container's Linux distribution

### Nix packages not found
- The feature uses `/cache` for the Nix store cache
- First run may take longer while packages are downloaded
- Subsequent containers will be faster due to shared cache

## License

MIT License - See LICENSE file for details
