#!/bin/bash
set -e

# This script installs Nix and home-manager in a devcontainer
# It's run at build time (when the container image is built)

echo "Installing Nix and home-manager..."

# Get the version option
NIX_VERSION="${NIXVERSION:-25.11}"

# Ensure we're running as root for installation
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root during container build"
    exit 1
fi

# Create nix directories
mkdir -p /nix /etc/nix /cache

# Configure Nix for no-daemon mode
cat > /etc/nix/nix.conf << 'EOF'
experimental-features = nix-command flakes
max-jobs = auto
cores = 0
sandbox = false
# Use /cache for the nix store cache
extra-substituters = file:///cache
trusted-users = root @wheel
EOF

# Install Nix (no-daemon mode as required for containers)
echo "Installing Nix in no-daemon mode..."
echo "This may take a few minutes..."
if [ ! -d /nix/store ]; then
    # Download and run Nix installer in single-user mode
    # Using --no-daemon as home-manager is CLI-only, not a persistent service
    # Note: This uses the official Nix installation method from nixos.org
    # While piping to sh has security considerations, this is the standard
    # installation method recommended by the Nix project. For enhanced security,
    # users should verify the script manually before running the feature.
    curl -L https://nixos.org/nix/install | sh -s -- --no-daemon --yes 2>&1 | tee /tmp/nix-install.log
    echo "Nix installation completed"
else
    echo "Nix already installed, skipping"
fi

# Source nix profile to make nix available (no-daemon mode)
if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix.sh ]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
fi

# Add nix to PATH for all users
cat > /etc/profile.d/nix.sh << 'EOF'
# Source Nix profile (no-daemon mode)
if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix.sh ]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
fi
EOF

# Make the profile script executable
chmod +x /etc/profile.d/nix.sh

# Install home-manager using nix
echo "Installing home-manager..."
echo "Version: $NIX_VERSION"
# Use the version specified in nixVersion option (defaults to LTS 25.11)
if [ "$NIX_VERSION" = "latest" ]; then
    # Use master branch for latest
    echo "Using latest (master) branch"
    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
else
    # Use release branch for specific version
    echo "Using release-${NIX_VERSION} branch"
    nix-channel --add https://github.com/nix-community/home-manager/archive/release-${NIX_VERSION}.tar.gz home-manager
fi
echo "Updating nix channels..."
nix-channel --update 2>&1 | tee /tmp/nix-channel-update.log

# Install home-manager
echo "Installing home-manager package..."
export NIX_PATH=$HOME/.nix-defexpr/channels:/nix/var/nix/profiles/per-user/root/channels${NIX_PATH:+:$NIX_PATH}
nix-shell '<home-manager>' -A install 2>&1 | tee /tmp/home-manager-install.log || {
    echo "home-manager install via nix-shell failed, trying direct install..."
    nix-env -iA nixpkgs.home-manager 2>&1 | tee /tmp/home-manager-direct-install.log
}
echo "home-manager installation completed"

# Copy the startup script to a standard location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/home-manager-setup.sh" ]; then
    cp "$SCRIPT_DIR/home-manager-setup.sh" /usr/local/share/home-manager-setup.sh
elif [ -f "/tmp/build-features/home-manager/home-manager-setup.sh" ]; then
    cp /tmp/build-features/home-manager/home-manager-setup.sh /usr/local/share/home-manager-setup.sh
else
    echo "Warning: home-manager-setup.sh not found, looking in alternate locations..."
    # Try to find it
    find /tmp -name "home-manager-setup.sh" -exec cp {} /usr/local/share/home-manager-setup.sh \; 2>/dev/null || true
fi
chmod +x /usr/local/share/home-manager-setup.sh 2>/dev/null || true

echo "Nix and home-manager installation complete!"
echo "home-manager will be configured on first container startup using HOME_MANAGER_GIT_URL environment variable"
