#!/bin/bash
set -e

# Determine the username to create.
# Feature options are passed as uppercase env vars with underscores.
# For option "username", the env var is "USERNAME".
#
# Behavior:
# - If USERNAME is set to a non-empty value other than 'automatic', use it.
# - Otherwise, derive it from the effective dev container user (remoteUser),
#   falling back to a sensible non-root default.

RAW_USERNAME="${USERNAME:-automatic}"

if [ -z "${RAW_USERNAME}" ] || [ "${RAW_USERNAME}" = "automatic" ]; then
  # Prefer the effective remote user, if provided by the devcontainer CLI.
  # See: https://containers.dev/implementors/features/#user-env-var
  if [ -n "${_REMOTE_USER}" ] && [ "${_REMOTE_USER}" != "root" ]; then
    USERNAME="${_REMOTE_USER}"
  elif [ -n "${_CONTAINER_USER}" ] && [ "${_CONTAINER_USER}" != "root" ]; then
    USERNAME="${_CONTAINER_USER}"
  else
    # As a final fallback, try the UID 1000 account, or default to 'devcontainer'.
    USERNAME="$(getent passwd 1000 | cut -d: -f1 || true)"
    if [ -z "${USERNAME}" ] || [ "${USERNAME}" = "root" ]; then
      USERNAME="devcontainer"
    fi
  fi
else
  USERNAME="${RAW_USERNAME}"
fi

echo "==========================================================================="
echo "Feature       : user-sync"
echo "Description   : Creates user matching host for file permission sync"
echo "Id            : user-sync"
echo "Version       : 1.0.0"
echo "Username      : ${USERNAME}"
echo "==========================================================================="

# Validate USERNAME is set and not empty
if [ -z "${USERNAME}" ]; then
  echo "Error: USERNAME could not be determined"
  echo "Please either set the 'username' option explicitly or ensure the devcontainer CLI is providing a non-root remoteUser."
  exit 1
fi

# Remove existing regular users (UID >= 1000, except nobody)
# This ensures we don't conflict with users created by base images
getent passwd \
  | awk -F: '($3 >= 1000) && ($1 != "nobody") {print $1}' \
  | xargs -r -n 1 userdel -r 2>/dev/null || true

# Create the user if not root
if [ "${USERNAME}" != "root" ]; then
  # Remove any existing group with GID 1000 (may be leftover from deleted users)
  EXISTING_GID_1000_GROUP=$(getent group 1000 | cut -d: -f1 || true)
  if [ -n "$EXISTING_GID_1000_GROUP" ]; then
    groupdel "$EXISTING_GID_1000_GROUP" 2>/dev/null || true
  fi

  # Create group with GID 1000
  groupadd --gid 1000 "${USERNAME}"

  # Create user with home directory
  useradd -s /bin/bash -m -u 1000 -g "${USERNAME}" "${USERNAME}"

  # Set up passwordless sudo
  mkdir -p /etc/sudoers.d
  echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" | tee "/etc/sudoers.d/${USERNAME}" > /dev/null
  chmod 0440 "/etc/sudoers.d/${USERNAME}"
  
  # Verify the file was created
  if [ -f "/etc/sudoers.d/${USERNAME}" ]; then
    echo "✓ Sudoers file /etc/sudoers.d/${USERNAME} created successfully"
  else
    echo "✗ Error: Sudoers file /etc/sudoers.d/${USERNAME} was not created!"
    exit 1
  fi

  echo "Created user '${USERNAME}' with UID 1000, GID 1000"
else
  echo "Username is root, skipping user creation"
fi
