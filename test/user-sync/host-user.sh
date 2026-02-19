#!/bin/bash
set -e

source dev-container-features-test-lib

TARGET_USER=$(getent passwd 1000 | cut -d: -f1)

check "uid 1000 user exists"           bash -c 'getent passwd 1000 | grep -q .'
check "uid 1000 user has home dir"     bash -c "test -d /home/${TARGET_USER}"
check "uid 1000 user has sudoers file" bash -c "test -f /etc/sudoers.d/${TARGET_USER}"

reportResults
