#!/bin/bash
# Run on the lab host. Creates the routed vSAN networks and DHCP reservations for management.
set -euo pipefail
export LIBVIRT_DEFAULT_URI=qemu:///system

mk() { # name bridge gateway_ip
cat > /tmp/$1.xml <<XML
<network>
  <name>$1</name>
  <forward mode="route"/>
  <bridge name="$2" stp="off"/>
  <mtu size="9000"/>
  <ip address="$3" netmask="255.255.255.0"/>
</network>
XML
virsh net-define /tmp/$1.xml; virsh net-autostart $1; virsh net-start $1
}
mk dc-stretch br-dc      10.10.0.1   # sites 1+2: one stretched L2
mk witness    br-witness 10.10.3.1   # site 3: routed through the host

add() { virsh net-update default add ip-dhcp-host "<host mac=\"$1\" name=\"$2\" ip=\"$3\"/>" --live --config; }
add 52:54:00:10:01:11 esxi-s1-01  192.168.122.11
add 52:54:00:10:01:12 esxi-s1-02  192.168.122.12
add 52:54:00:10:02:21 esxi-s2-01  192.168.122.21
add 52:54:00:10:02:22 esxi-s2-02  192.168.122.22
add 52:54:00:10:03:30 esxi-witness 192.168.122.30
virsh net-list --all
