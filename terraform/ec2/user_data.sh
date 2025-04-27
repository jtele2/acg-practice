##############################################################################
# NOT WORKING - I SWITCH TO ANSIBLE (19-Apr-2025)
##############################################################################

#!/bin/bash

# Installs nix on Ubuntu 22.04 and sets up your Nix shell environment

set -o errexit  # Exit immediately if a command exits with a non-zero status
set -o nounset  # Treat unset variables as an error and exit immediately
set -o pipefail # Return the exit status of the last command in the pipeline that failed
set -o xtrace   # Print commands and their arguments before executing them

export HOME=/home/ubuntu

if ! sudo -u ubuntu command -v nix-env >/dev/null 2>&1; then
  curl -L https://nixos.org/nix/install \
    | sudo -u ubuntu sh -s -- --daemon
fi

# Add the Nix profile to the shell startup files
# The $$ escapes $HOME so Terraform won’t touch it
NIX_PROFILE_LINE='. "$${HOME}/.nix-profile/etc/profile.d/nix.sh"'
grep --quiet --line-regexp --fixed-strings "$NIX_PROFILE_LINE" /home/ubuntu/.profile \
  || echo "$NIX_PROFILE_LINE" | sudo tee --append /home/ubuntu/.profile

sudo -u ubuntu mkdir -p /home/ubuntu/nix

# Add the Nix profile to the shell startup files
# This one _is_ Terraform interpolation, so leave it single‐dollar
echo "${shell_nix_base64}" \
  | base64 -d \
  | sudo -u ubuntu tee /home/ubuntu/nix/shell.nix >/dev/null
sudo chown -R ubuntu:ubuntu /home/ubuntu/nix

# Add nix-shell to the shell startup files
for f in .bashrc .zshrc .profile; do
  FILE="/home/ubuntu/$f"
  # escape $IN_NIX_SHELL and ~/ so they survive Terraform’s pass
  LINE='if [ -z "$$IN_NIX_SHELL" ]; then nix-shell ~/nix/shell.nix; fi'
  grep -qxF "$LINE" "$FILE" \
    || echo "$LINE" | sudo tee -a "$FILE"
done
