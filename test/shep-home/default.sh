#!/bin/bash
set -e

source dev-container-features-test-lib

# Look up the UID-1000 user dynamically — no hardcoded usernames.
TARGET_USER=$(getent passwd 1000 | cut -d: -f1)

check "nix is installed" \
  bash -c "su - ${TARGET_USER} -c 'source ~/.nix-profile/etc/profile.d/nix.sh && nix --version'"

check "home-manager generations exist" \
  bash -c "su - ${TARGET_USER} -c 'test -d ~/.local/state/nix/profiles'"

check "ripgrep is available" \
  bash -c "su - ${TARGET_USER} -c 'source ~/.nix-profile/etc/profile.d/nix.sh && which rg'"

reportResults
