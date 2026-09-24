#!/bin/bash
# usage: mkesxi.sh name mac1 mac2 net2
set -e
export LIBVIRT_DEFAULT_URI=qemu:///system
N=$1; M1=$2; M2=$3; NET2=$4
qemu-img create -f qcow2 /data/vms/$N-os.qcow2 32G >/dev/null
virt-install --name $N --memory 8192 --vcpus 2 --cpu host-passthrough \
  --os-variant generic --boot hd,cdrom --graphics vnc,listen=127.0.0.1 \
  --disk path=/data/vms/$N-os.qcow2,bus=sata \
  --disk path=/mnt/iso/esxi-ks.iso,device=cdrom,bus=sata \
  --network network=default,model=e1000e,mac=$M1 \
  --network network=$NET2,model=e1000e,mac=$M2 \
  --noautoconsole --import
