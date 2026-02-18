# Examples

This directory contains example configurations to help you get started with shep-home.

## Files

### devcontainer.json
Example devcontainer configuration showing how to:
- Add the home-manager feature
- Set the HOME_MANAGER_GIT_URL environment variable
- Mount SSH keys for private repository access

### flake.nix
Example Nix flake configuration for home-manager with:
- Basic flake structure
- home-manager input
- homeConfiguration for a user

### home.nix
Example home-manager configuration with:
- Common CLI tools
- Git configuration
- Shell configuration (bash/zsh)
- Environment variables

## Quick Start

1. Copy `flake.nix` and `home.nix` to your own private git repository
2. Customize the configuration to your preferences
3. Update your `devcontainer.json` to point to your repository
4. Rebuild your dev container

Your personal environment will be automatically configured on container startup!
