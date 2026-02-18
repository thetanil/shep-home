#!/bin/bash
set -e

# This script runs on container startup (onCreateCommand)
# It clones the user's home-manager configuration and runs home-manager switch

echo "Setting up home-manager configuration..."

# Check if HOME_MANAGER_GIT_URL is set
if [ -z "${HOME_MANAGER_GIT_URL}" ]; then
    echo "HOME_MANAGER_GIT_URL environment variable not set."
    echo "Skipping home-manager configuration."
    echo "To use home-manager, set HOME_MANAGER_GIT_URL to your private git repository URL."
    exit 0
fi

echo "Using home-manager configuration from: ${HOME_MANAGER_GIT_URL}"

# Source nix profile to ensure nix and home-manager are available
if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
elif [ -f /nix/var/nix/profiles/default/etc/profile.d/nix.sh ]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
elif [ -f ~/.nix-profile/etc/profile.d/nix.sh ]; then
    . ~/.nix-profile/etc/profile.d/nix.sh
fi

# Determine the user home directory
USER_HOME="${HOME:-/home/${USER}}"
CONFIG_DIR="${USER_HOME}/.config/home-manager"

# Create config directory if it doesn't exist
mkdir -p "${CONFIG_DIR}"

# Clone or update the repository
if [ -d "${CONFIG_DIR}/.git" ]; then
    echo "Home-manager config repository already exists, pulling latest changes..."
    cd "${CONFIG_DIR}"
    git pull || echo "Warning: Failed to pull latest changes"
else
    echo "Cloning home-manager configuration repository..."
    # Remove directory if it exists but is not a git repo
    if [ -d "${CONFIG_DIR}" ] && [ ! -d "${CONFIG_DIR}/.git" ]; then
        rm -rf "${CONFIG_DIR}"
    fi
    
    # Clone the repository
    git clone "${HOME_MANAGER_GIT_URL}" "${CONFIG_DIR}" || {
        echo "Error: Failed to clone repository ${HOME_MANAGER_GIT_URL}"
        echo "Make sure the repository is accessible and you have proper authentication configured."
        exit 1
    }
fi

# Change to config directory
cd "${CONFIG_DIR}"

# Check if there's a flake.nix file
if [ -f "flake.nix" ]; then
    echo "Found flake.nix, using flakes-based home-manager..."
    # Use home-manager with flakes
    home-manager switch --flake .#${USER} || {
        echo "Failed to switch with user-specific configuration, trying default..."
        home-manager switch --flake . || {
            echo "Error: Failed to apply home-manager configuration"
            exit 1
        }
    }
elif [ -f "home.nix" ]; then
    echo "Found home.nix, using traditional home-manager..."
    # Traditional home-manager configuration
    home-manager switch || {
        echo "Error: Failed to apply home-manager configuration"
        exit 1
    }
else
    echo "Error: No flake.nix or home.nix found in ${CONFIG_DIR}"
    echo "Your repository must contain either a flake.nix or home.nix file"
    exit 1
fi

echo "Home-manager configuration applied successfully!"
echo "Your personal home environment is now configured."
