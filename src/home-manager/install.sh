#!/bin/bash
set -e

# This script installs Nix and home-manager in a devcontainer
# It's run at build time (when the container image is built)

echo "Installing Nix and home-manager..."

# Get the version option
NIX_VERSION="${NIXVERSION:-latest}"

# Ensure we're running as root for installation
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root during container build"
    exit 1
fi

# Create nix directories
mkdir -p /nix /etc/nix /cache

# Configure Nix to use /cache for store
cat > /etc/nix/nix.conf << 'EOF'
experimental-features = nix-command flakes
build-users-group = nixbld
max-jobs = auto
cores = 0
sandbox = false
# Use /cache for the nix store cache
extra-substituters = file:///cache
trusted-users = root @wheel
EOF

# Install Nix (multi-user installation)
echo "Installing Nix..."
if [ ! -d /nix/store ]; then
    # Download and run Nix installer
    curl -L https://nixos.org/nix/install | sh -s -- --daemon --yes || {
        echo "Failed to install Nix with daemon, trying no-daemon mode..."
        # If daemon install fails (common in containers), try single-user
        curl -L https://nixos.org/nix/install | sh -s -- --no-daemon --yes
    }
fi

# Source nix profile to make nix available
if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
elif [ -f /nix/var/nix/profiles/default/etc/profile.d/nix.sh ]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
fi

# Add nix to PATH for all users
cat > /etc/profile.d/nix.sh << 'EOF'
# Source Nix profile
if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
elif [ -f /nix/var/nix/profiles/default/etc/profile.d/nix.sh ]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
fi
EOF

# Make the profile script executable
chmod +x /etc/profile.d/nix.sh

# Install home-manager using nix
echo "Installing home-manager..."
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update

# Install home-manager
export NIX_PATH=$HOME/.nix-defexpr/channels:/nix/var/nix/profiles/per-user/root/channels${NIX_PATH:+:$NIX_PATH}
nix-shell '<home-manager>' -A install || {
    echo "home-manager install via nix-shell failed, trying direct install..."
    nix-env -iA nixpkgs.home-manager
}

# Copy the startup script to a standard location
cp /tmp/build-features/home-manager/home-manager-setup.sh /usr/local/share/home-manager-setup.sh
chmod +x /usr/local/share/home-manager-setup.sh

echo "Nix and home-manager installation complete!"
echo "home-manager will be configured on first container startup using HOME_MANAGER_GIT_URL environment variable"
