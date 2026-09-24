# Scripts

Run on `vcf-lab-host` (the Azure VM created by Terraform), in this order:

| Script | Purpose |
|---|---|
| `01-setup-kvm-host.sh` | Install KVM/libvirt, mount the Azure data disks |
| `02-libvirt-networks.sh` | Routed vSAN networks (MTU 9000) + DHCP reservations |
| `03-serve-kickstart.sh` | Serve the kickstart over HTTP and build the ESXi ISO |
| `mkesxi.sh` | Create one nested ESXi VM (`mkesxi.sh <name> <mac1> <mac2> <net2>`) |
| `cfg-esxi.sh` | Post-install config of one ESXi host (vSAN network, SSD flag) |
| `ks.cfg` | ESXi kickstart |
| `vcsa.json` | vCenter (VCSA tiny) deployment template |

`ks.cfg` and `vcsa.json` use the placeholder `CHANGE_ME_LAB_PASSWORD`: replace it before use.

Scripts 01-03 were reconstructed from the commands run interactively and were **not re-run as scripts**;
`mkesxi.sh`, `ks.cfg` and `vcsa.json` are the exact files used. `cfg-esxi.sh` was corrected after the
first run (VSAN tag name, SSD flag through HPP, persistence across reboots).
Disk device names (`/dev/sdc`, `/dev/sdd`) can differ: check with `lsblk` first.
