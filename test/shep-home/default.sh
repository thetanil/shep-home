#!/bin/bash
set -e

source dev-container-features-test-lib

# Look up the non-root user dynamically. Most systems use UID 1000, but GH
# runners use UID 1001. Try 1000 first, fall back to 1001.
TARGET_USER=$(getent passwd 1000 | cut -d: -f1)
if [ -z "${TARGET_USER}" ]; then
  TARGET_USER=$(getent passwd 1001 | cut -d: -f1)
fi

TARGET_HOME="$(getent passwd "${TARGET_USER}" | cut -d: -f6)"

echo "TARGET_USER=${TARGET_USER} TARGET_HOME=${TARGET_HOME} whoami=$(whoami) uid=$(id -u)"
ls -la "${TARGET_HOME}/.nix-profile" 2>&1 || echo "no .nix-profile symlink"
ls "${TARGET_HOME}/.nix-profile/bin/nix" 2>&1 || echo "no nix binary in .nix-profile/bin"

check "nix is installed" \
  bash -c "PATH=${TARGET_HOME}/.nix-profile/bin:\$PATH nix --version"

check "home-manager generations exist" \
  test -d "${TARGET_HOME}/.local/state/nix/profiles"

check "ripgrep is available" \
  bash -c "PATH=${TARGET_HOME}/.nix-profile/bin:\$PATH which rg"

reportResults
