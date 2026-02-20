#!/bin/bash
set -e

# Resolve the target username — same pattern as user-sync.
# CONFIGURL is the feature option (uppercase env var).
CONFIGURL="${CONFIGURL:-bundled}"

# shep-home requires user-sync to have already created the UID-1000 user.
USERNAME="$(getent passwd 1000 | cut -d: -f1 || true)"
if [ -z "${USERNAME}" ] || [ "${USERNAME}" = "root" ]; then
  echo "No non-root user at UID 1000 found; skipping home-manager configuration."
  echo "Ensure the user-sync feature runs before shep-home in real usage."
  exit 1
fi

echo "==========================================================================="
echo "Feature       : shep-home"
echo "Description   : Applies home-manager flake configuration as the user-sync user"
echo "Id            : shep-home"
echo "Version       : 1.0.0"
echo "Username      : ${USERNAME}"
echo "Config URL    : ${CONFIGURL}"
echo "==========================================================================="

USER_HOME="/home/${USERNAME}"

# ---------------------------------------------------------------------------
# 1. Fetch / copy the home-manager config
# ---------------------------------------------------------------------------
CONFIG_DEST="${USER_HOME}/.config/home-manager"
mkdir -p "${CONFIG_DEST}"

if [ "${CONFIGURL}" = "bundled" ]; then
  echo "Copying bundled example config..."
  cp -r "$(dirname "$0")/example/." "${CONFIG_DEST}/"
else
  echo "Cloning config from ${CONFIGURL}..."
  git clone "${CONFIGURL}" "${CONFIG_DEST}"
fi

chown -R "${USERNAME}:${USERNAME}" "${CONFIG_DEST}"

# Enable nix-command and flakes for the user so home-manager can run.
mkdir -p "${USER_HOME}/.config/nix"
echo 'experimental-features = nix-command flakes' > "${USER_HOME}/.config/nix/nix.conf"
mkdir -p "${USER_HOME}/.config/systemd/user"
chown -R "${USERNAME}:${USERNAME}" "${USER_HOME}/.config"

# ---------------------------------------------------------------------------
# 2. Install deps, then run Nix + home-manager at build time
# ---------------------------------------------------------------------------
apt-get update -y
apt-get install -y --no-install-recommends curl ca-certificates xz-utils git sudo

echo "Running home-manager switch as ${USERNAME}..."
su - "${USERNAME}" -c '
  set -e
  sh <(curl --proto '"'"'=https'"'"' --tlsv1.2 -L https://nixos.org/nix/install) --no-daemon
  . "${HOME}/.nix-profile/etc/profile.d/nix.sh"
  nix run home-manager/master -- switch --flake "${HOME}/.config/home-manager#'"${USERNAME}"'" --impure -b backup
'

echo "shep-home: done."
