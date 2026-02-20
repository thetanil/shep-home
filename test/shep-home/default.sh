#!/bin/bash
set -e

source dev-container-features-test-lib

# Look up the UID-1000 user dynamically — no hardcoded usernames.
TARGET_USER=$(getent passwd 1000 | cut -d: -f1)

TARGET_HOME="$(getent passwd "${TARGET_USER}" | cut -d: -f6)"

check "nix is installed" \
  bash -c "PATH=${TARGET_HOME}/.nix-profile/bin:\$PATH nix --version"

check "home-manager generations exist" \
  test -d "${TARGET_HOME}/.local/state/nix/profiles"

check "ripgrep is available" \
  bash -c "PATH=${TARGET_HOME}/.nix-profile/bin:\$PATH which rg"

reportResults
