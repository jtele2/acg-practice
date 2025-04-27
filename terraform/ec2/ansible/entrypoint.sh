#!/bin/bash

# - `set -e`: Exit immediately if a command exits with a non-zero status.
# - `set -u`: Treat unset variables as an error and exit immediately.
# - `set -o pipefail`: Return the exit status of the last command in the pipeline that failed, if any.
set -euo pipefail

# Set up SSH authorized keys
mkdir -p /home/ubuntu/.ssh


# → Copy authorized_keys at container start, not at build time
# ✅ Volume-mount the pubkey into /tmp/authorized_key
# ✅ At container start, move it into the ubuntu user's .ssh/authorized_keys
# ✅ No secrets baked into Docker images
# ✅ Linting clean, security clean
if [ -f /tmp/authorized_key ]; then
    echo "Installing SSH authorized key"
    cp /tmp/authorized_key /home/ubuntu/.ssh/authorized_keys
    chown -R ubuntu:ubuntu /home/ubuntu/.ssh
    chmod 700 /home/ubuntu/.ssh
    chmod 600 /home/ubuntu/.ssh/authorized_keys
else
    echo "No authorized_key found, skipping SSH key setup"
fi

# → When the container starts, boot into systemd, not just bash or sleep.
# This mimics a real VM lifecycle — systemd spawns services like sshd, etc.
exec /lib/systemd/systemd
