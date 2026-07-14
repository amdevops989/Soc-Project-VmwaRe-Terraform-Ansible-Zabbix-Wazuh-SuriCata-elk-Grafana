#!/bin/bash -eux
echo "==> remove SSH keys used for building"
rm -f /home/ubuntu/.ssh/authorized_keys
rm -f /root/.ssh/authorized_keys

echo "==> Clear out machine id"
truncate -s 0 /etc/machine-id

echo "==> Remove the contents of /tmp and /var/tmp"
rm -rf /tmp/* /var/tmp/*

echo "==> Truncate any logs that have built up during the install"
find /var/log -type f -exec truncate --size=0 {} \;

echo "==> Cleanup bash history"
rm -f ~/.bash_history



echo "remove /usr/share/doc/"
rm -rf /usr/share/doc/*

echo "==> remove /var/cache"
find /var/cache -type f -exec rm -rf {} \;

echo "==> Cleanup apt"
apt-get -y autoremove
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*

echo "==> force a new random seed to be generated"
rm -f /var/lib/systemd/random-seed

echo "==> Clear the history so our install isn't there"
rm -f /root/.wget-hsts

# 1. Write clean Netplan configuration
sudo mkdir -p /etc/netplan
sudo tee /etc/netplan/01-netcfg.yaml << 'EOF'
network:
  version: 2
  renderer: networkd
  ethernets:
    ens3:
      dhcp4: true
      match:
        name: ens*
EOF

# 2. Apply strict secure permissions to avoid Netplan warnings
sudo chmod 600 /etc/netplan/01-netcfg.yaml

# 3. Wipe out Cloud-Init dynamic state artifacts so it re-runs on your KVM host
echo "🧹 Purging Cloud-Init machine cache footprints..."
sudo rm -rf /var/lib/cloud/instances/*
sudo cloud-init clean --logs

# 4. Clear machine-id so it pulls unique DHCP leases across multiple VMs
sudo truncate -s 0 /etc/machine-id
sudo rm -f /var/lib/dbus/machine-id
sudo ln -s /etc/machine-id /var/lib/dbus/machine-id

export HISTSIZE=0