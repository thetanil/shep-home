#!/bin/bash
set -e

echo "==========================================================================="
echo "Feature       : user-sync"
echo "Description   : Creates user matching host for file permission sync"
echo "Id            : user-sync"
echo "Version       : 1.0.0"
echo "Username      : ${USERNAME}"
echo "==========================================================================="

# Validate USERNAME is set and not empty
if [ -z "${USERNAME}" ]; then
  echo "Error: USERNAME environment variable is not set or is empty"
  echo "Please set USERNAME before running this script:"
  echo "  export USERNAME=<your-username>"
  echo "  sudo -E bash install.sh"
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
  echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/${USERNAME}"
  chmod 0440 "/etc/sudoers.d/${USERNAME}"

  echo "Created user '${USERNAME}' with UID 1000, GID 1000"
else
  echo "Username is root, skipping user creation"
fi
