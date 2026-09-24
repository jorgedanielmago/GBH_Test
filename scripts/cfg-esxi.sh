#!/bin/sh
# Post-install config for one nested ESXi host (run on the ESXi host over SSH).
# usage: sh -s -- <vsan_ip> <gateway_of_vsan_net> <remote_route_cidr> < cfg-esxi.sh
#   data hosts: 10.10.0.<n> 10.10.0.1 10.10.3.0/24
#   witness   : 10.10.3.30  10.10.3.1 10.10.0.0/24
set -e
VSAN_IP=$1; GW=$2; ROUTE=$3

# vSAN network: dedicated vSwitch, jumbo frames, static VMkernel port tagged for vSAN
esxcli network vswitch standard add -v vSwitch1
esxcli network vswitch standard uplink add -v vSwitch1 -u vmnic1
esxcli network vswitch standard set -v vSwitch1 -m 9000
esxcli network vswitch standard portgroup add -v vSwitch1 -p vSAN
esxcli network ip interface add -i vmk1 -p vSAN -m 9000
esxcli network ip interface ipv4 set -i vmk1 -t static -I "$VSAN_IP" -N 255.255.255.0
esxcli network ip interface tag add -i vmk1 -t VSAN
esxcli network ip route ipv4 add -n "$ROUTE" -g "$GW"

# Mark the cache disk as SSD. Local SATA disks are claimed by HPP, not NMP,
# so the SATP enable_ssd rule has no effect. The flag is lost on reboot,
# so re-apply it from local.sh.
DEV=$(esxcli storage core device list | grep -E "^t10.*CACHE")
esxcli storage hpp device set -d "$DEV" --mark-device-ssd=true
sed -i '/^exit 0/d' /etc/rc.local.d/local.sh
cat >> /etc/rc.local.d/local.sh <<'EOL'
sleep 30
DEV=$(esxcli storage core device list | grep -E "^t10.*CACHE")
esxcli storage hpp device set -d $DEV --mark-device-ssd=true
exit 0
EOL
/sbin/auto-backup.sh >/dev/null 2>&1

esxcli storage core device list -d "$DEV" | grep "Is SSD"
esxcli network ip interface ipv4 get -i vmk1 | tail -1
