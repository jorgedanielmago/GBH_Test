#!/bin/bash
# Run on the Azure lab host (Ubuntu 22.04). Installs KVM/libvirt and mounts the data disks.
# Assumes /dev/sdc (capacity) and /dev/sdd (cache) are the EMPTY Azure data disks: verify with lsblk first.
set -euo pipefail
sudo apt-get update -qq
sudo apt-get install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virtinst cpu-checker genisoimage xorriso sshpass
sudo usermod -aG libvirt,kvm "$USER"
echo 'export LIBVIRT_DEFAULT_URI=qemu:///system' >> ~/.bashrc   # without this virsh uses the user session and cannot create bridges
kvm-ok && cat /sys/module/kvm_intel/parameters/nested           # expect: nested=Y

sudo mkfs.ext4 -q -L vmdata  /dev/sdc
sudo mkfs.ext4 -q -L vmcache /dev/sdd
sudo mkdir -p /data/vms /data/cache /mnt/iso
echo "LABEL=vmdata  /data/vms   ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
echo "LABEL=vmcache /data/cache ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
sudo mount -a
sudo chown "$USER":libvirt /data/vms /data/cache
sudo chown "$USER":"$USER" /mnt/iso   # /mnt is Azure's ephemeral disk: ISOs only
df -h /data/vms /data/cache
