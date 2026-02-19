#!/bin/bash
set -e

source dev-container-features-test-lib

# The devcontainer CLI remaps the in-image UID to match the host user's UID
# (via updateContainerUserID). Use the actual running UID, not the hardcoded
# build-time UID of 1000, so the test works on any host (local or CI runner).
HOST_UID=$(id -u)
TARGET_USER=$(getent passwd "${HOST_UID}" | cut -d: -f1)

check "host uid user exists"           bash -c "getent passwd ${HOST_UID} | grep -q ."
check "host uid user has home dir"     bash -c "test -d /home/${TARGET_USER}"
check "host uid user has sudoers file" bash -c "test -f /etc/sudoers.d/${TARGET_USER}"

reportResults
