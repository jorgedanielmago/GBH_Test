# ==============================================================================
# modules/nested_host — one VM shell + NIC + (optionally) vSAN cache/capacity disks
# ==============================================================================

# Optional public IP (only used for the single KVM lab host, so it can be
# reached over SSH from the admin workstation; NSG restricts the source IP).
resource "azurerm_public_ip" "this" {
  count               = var.public_ip ? 1 : 0
  name                = "${var.vm_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "this" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.public_ip ? azurerm_public_ip.this[0].id : null
  }
}

# Data disks representing the vSAN cache and capacity tiers. Real disk
# content is irrelevant here — they exist so that once ESXi is installed
# (manually, via attached ISO + serial console — see build guide), vSAN
# has raw devices to consume when you enable it on the cluster.
resource "azurerm_managed_disk" "vsan_cache" {
  count                = var.attach_vsan_disks ? 1 : 0
  name                 = "${var.vm_name}-vsan-cache"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.cache_disk_size_gb
}

resource "azurerm_managed_disk" "vsan_capacity" {
  count                = var.attach_vsan_disks ? 1 : 0
  name                 = "${var.vm_name}-vsan-capacity"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = "StandardSSD_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.capacity_disk_size_gb
}

# Base VM shell. Deployed from a minimal Ubuntu image as a placeholder —
# the OS disk gets overwritten by the ESXi installer during the manual
# install step described in the build guide. Using a throwaway published
# image here (instead of leaving the VM blank) is what lets Azure actually
# provision compute/disks/NIC together in one deployment.
resource "azurerm_linux_virtual_machine" "this" {
  name                = var.vm_name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.this.id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb          = 64
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  disable_password_authentication = true

  # Required for Azure Serial Console access
  boot_diagnostics {}
}

resource "azurerm_virtual_machine_data_disk_attachment" "vsan_cache" {
  count              = var.attach_vsan_disks ? 1 : 0
  managed_disk_id    = azurerm_managed_disk.vsan_cache[0].id
  virtual_machine_id = azurerm_linux_virtual_machine.this.id
  lun                = 0
  caching            = "None"
}

resource "azurerm_virtual_machine_data_disk_attachment" "vsan_capacity" {
  count              = var.attach_vsan_disks ? 1 : 0
  managed_disk_id    = azurerm_managed_disk.vsan_capacity[0].id
  virtual_machine_id = azurerm_linux_virtual_machine.this.id
  lun                = 1
  caching            = "None"
}
