# ##################################################################
# Docker Container for Ansible Playbooks to Replicate the AWS AMI
# ##################################################################

# Use the official Ubuntu 22.04 base image
# Ubuntu 22.04 = what AWS is using today for most ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-* AMIs.
FROM ubuntu:22.04

# Prevents apt from popping interactive prompts (timezone selection, service restarts, etc.)
# Required or your build will hang.
ENV DEBIAN_FRONTEND=noninteractive

# ##################################################################
# Install the packages needed to run Ansible playbooks against AWS AMIs
# Package	        Why it's needed
# systemd	        Makes the container boot like a real Linux system (handles services like sshd). AWS AMIs use systemd.
# systemd-sysv	    Compatibility layer to support service ssh start and SysV-style scripts under systemd.
# sudo	            You’ll need it for non-root users or typical Ansible privilege escalation.
# openssh-server	So you can SSH into the container (just like you would into an EC2 instance).
# python3	        Ansible needs Python on the managed node, period.
# python3-pip	    Just nice to have if you later need to install stuff from PyPI inside the container.
# net-tools	        Basic networking tools like ifconfig, netstat — AWS AMIs still come with these.
# iproute2	        Modern networking tools (ip addr, ip route). Required for network stuff.

RUN apt-get update && apt-get install -y \
    systemd \
    systemd-sysv \
    sudo \
    openssh-server \
    python3 \
    python3-pip \
    net-tools \
    iproute2 \
    && apt-get clean

# ##################################################################
# Setup Commands

# → SSH daemon expects /var/run/sshd to exist. Docker Ubuntu images don’t always have it.
# If missing, sshd will crash.
# /var is where Linux writes things that it can't know at install-time.
RUN mkdir /var/run/sshd

# → Create 'ubuntu' user with passwordless sudo (AWS AMI default behavior)
RUN useradd -m -s /bin/bash ubuntu && \
    echo 'ubuntu:ubuntu' | chpasswd && \
    usermod -aG sudo ubuntu && \
    echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu-nopasswd

# → Copy in your public key so you don't need passwords
ARG SSH_PUB_KEY
RUN mkdir -p /home/ubuntu/.ssh && \
    echo "${SSH_PUB_KEY}" > /home/ubuntu/.ssh/authorized_keys && \
    chown -R ubuntu:ubuntu /home/ubuntu/.ssh && \
    chmod 700 /home/ubuntu/.ssh && \
    chmod 600 /home/ubuntu/.ssh/authorized_keys    

# → Patch SSH config:
# Disable root login (matches AWS defaults).
# Disable password authentication.
# Enable public key authentication.
# Disable PAM (because PAM can cause SSH sessions to hang in container environments).
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config

# → Tell systemd to automatically start sshd service on container boot.
# Without this, SSH won’t be running unless you manually start it every time.
RUN systemctl enable ssh

# ##################################################################
# Run Commands
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

CMD ["/usr/local/bin/entrypoint.sh"]
