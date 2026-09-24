# ==============================================================================
# GBH Private Cloud Design Exercise — Azure Sandbox Infrastructure (Terraform)
# ==============================================================================
# Deploys the network topology and VM shells for a scaled-down, two-site
# nested vSAN stretched cluster demo (2 hosts/site + 1 witness).
#
# IMPORTANT / HONEST LIMITATION:
# Azure has no native "boot from custom ISO" primitive the way an on-prem
# hypervisor does. This configuration provisions the network, NSGs, VM shells,
# and data disks (the fully automatable part). Installing ESXi itself onto
# each VM is a manual step after deployment: attach the ESXi ISO as a data
# disk (or build a custom image from a pre-converted VHD) and install via
# the Azure Serial Console / Boot Diagnostics.
#
# Deploy with:
#   terraform init
#   terraform plan -var="admin_ssh_public_key=$(cat ~/.ssh/id_rsa.pub)"
#   terraform apply -var="admin_ssh_public_key=$(cat ~/.ssh/id_rsa.pub)"
# ==============================================================================

locals {
  vnet_address_space     = ["10.20.0.0/16"]
  site1_subnet_prefix    = "10.20.1.0/24"
  site2_subnet_prefix    = "10.20.2.0/24"
  witness_subnet_prefix  = "10.20.3.0/24"
}

# ------------------------------------------------------------------------------
# Network Security Group — shared rules for ESXi / vCenter / vSAN / vMotion
# ------------------------------------------------------------------------------
resource "azurerm_network_security_group" "vcf_sandbox" {
  name                = "vcf-sandbox-nsg"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.sandbox.name

  security_rule {
    name                       = "Allow-ESXi-Mgmt-HTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-ESXi-Mgmt-902"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "902"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-vMotion"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8000-8200"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                         = "Allow-vSAN-Cluster"
    priority                     = 130
    direction                    = "Inbound"
    access                       = "Allow"
    protocol                     = "*"
    source_port_range            = "*"
    destination_port_ranges      = ["2233", "12321", "12345"]
    source_address_prefix        = "VirtualNetwork"
    destination_address_prefix   = "*"
  }

  security_rule {
    name                       = "Allow-SSH-From-Admin"
    priority                   = 150
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.admin_source_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH-Mgmt"
    priority                   = 140
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
}

# ------------------------------------------------------------------------------
# VNet + 3 subnets (Site 1 / Site 2 / Witness)
# ------------------------------------------------------------------------------
resource "azurerm_virtual_network" "vcf_sandbox" {
  name                = "vcf-sandbox-vnet"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.sandbox.name
  address_space       = local.vnet_address_space
}

resource "azurerm_subnet" "site1" {
  name                 = "site1-subnet"
  resource_group_name  = data.azurerm_resource_group.sandbox.name
  virtual_network_name = azurerm_virtual_network.vcf_sandbox.name
  address_prefixes     = [local.site1_subnet_prefix]
}

resource "azurerm_subnet" "site2" {
  name                 = "site2-subnet"
  resource_group_name  = data.azurerm_resource_group.sandbox.name
  virtual_network_name = azurerm_virtual_network.vcf_sandbox.name
  address_prefixes     = [local.site2_subnet_prefix]
}

resource "azurerm_subnet" "witness" {
  name                 = "witness-subnet"
  resource_group_name  = data.azurerm_resource_group.sandbox.name
  virtual_network_name = azurerm_virtual_network.vcf_sandbox.name
  address_prefixes     = [local.witness_subnet_prefix]
}

resource "azurerm_subnet_network_security_group_association" "site1" {
  subnet_id                 = azurerm_subnet.site1.id
  network_security_group_id = azurerm_network_security_group.vcf_sandbox.id
}

resource "azurerm_subnet_network_security_group_association" "site2" {
  subnet_id                 = azurerm_subnet.site2.id
  network_security_group_id = azurerm_network_security_group.vcf_sandbox.id
}

resource "azurerm_subnet_network_security_group_association" "witness" {
  subnet_id                 = azurerm_subnet.witness.id
  network_security_group_id = azurerm_network_security_group.vcf_sandbox.id
}

# ------------------------------------------------------------------------------
# Site 1 host VMs (nested ESXi shells)
# ------------------------------------------------------------------------------
module "site1_hosts" {
  source   = "./modules/nested_host"
  for_each = { for i in range(var.hosts_per_site) : "site1-host${i + 1}" => i }

  vm_name               = each.key
  location              = var.location
  resource_group_name   = data.azurerm_resource_group.sandbox.name
  vm_size                = var.vm_size
  subnet_id              = azurerm_subnet.site1.id
  admin_username          = var.admin_username
  admin_ssh_public_key    = var.admin_ssh_public_key
  attach_vsan_disks       = true
}

# ------------------------------------------------------------------------------
# Site 2 host VMs (nested ESXi shells)
# ------------------------------------------------------------------------------
module "site2_hosts" {
  source   = "./modules/nested_host"
  for_each = { for i in range(var.hosts_per_site) : "site2-host${i + 1}" => i }

  vm_name               = each.key
  location              = var.location
  resource_group_name   = data.azurerm_resource_group.sandbox.name
  vm_size                = var.vm_size
  subnet_id              = azurerm_subnet.site2.id
  admin_username          = var.admin_username
  admin_ssh_public_key    = var.admin_ssh_public_key
  attach_vsan_disks       = true
}

# ------------------------------------------------------------------------------
# Witness VM (lightweight — no vSAN data disks needed, only metadata)
# ------------------------------------------------------------------------------
module "witness_host" {
  source = "./modules/nested_host"
  count  = var.deploy_witness ? 1 : 0

  vm_name              = "witness-host"
  location             = var.location
  resource_group_name  = data.azurerm_resource_group.sandbox.name
  vm_size              = var.witness_vm_size
  subnet_id            = azurerm_subnet.witness.id
  admin_username       = var.admin_username
  admin_ssh_public_key = var.admin_ssh_public_key
  attach_vsan_disks    = false
}

# ------------------------------------------------------------------------------
# KVM lab host (quota-constrained plan)
# ------------------------------------------------------------------------------
# Azure VMs expose only Hyper-V synthetic storage/network devices, which ESXi
# has no drivers for — so ESXi cannot be installed directly on an Azure VM.
# Instead, a single nested-virtualization-capable Ubuntu VM runs KVM, and the
# nested ESXi hosts (Site 1, Site 2), the vSAN witness and vCenter run as KVM
# guests inside it. With a 9-vCPU regional quota, one 8-vCPU lab host is the
# largest footprint that fits.
module "lab_host" {
  source = "./modules/nested_host"
  count  = var.deploy_lab_host ? 1 : 0

  vm_name               = "vcf-lab-host"
  location              = var.location
  resource_group_name   = data.azurerm_resource_group.sandbox.name
  vm_size               = var.lab_vm_size
  subnet_id             = azurerm_subnet.site1.id
  admin_username        = var.admin_username
  admin_ssh_public_key  = var.admin_ssh_public_key
  attach_vsan_disks     = true
  cache_disk_size_gb    = 64
  capacity_disk_size_gb = 512
  public_ip             = true
}
