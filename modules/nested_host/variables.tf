variable "vm_name" {
  description = "VM name (e.g., site1-host1)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "vm_size" {
  description = "VM size — must support nested virtualization"
  type        = string
}

variable "subnet_id" {
  description = "Resource ID of the subnet this host belongs to"
  type        = string
}

variable "admin_username" {
  description = "Admin username"
  type        = string
}

variable "admin_ssh_public_key" {
  description = "SSH public key for admin access"
  type        = string
  sensitive   = true
}

variable "attach_vsan_disks" {
  description = "Whether to attach vSAN cache + capacity data disks (false for the witness)"
  type        = bool
  default     = true
}

variable "cache_disk_size_gb" {
  description = "Size in GB of the simulated vSAN cache-tier disk"
  type        = number
  default     = 32
}

variable "capacity_disk_size_gb" {
  description = "Size in GB of the simulated vSAN capacity-tier disk"
  type        = number
  default     = 128
}

variable "public_ip" {
  description = "Whether to attach a Standard public IP to this VM"
  type        = bool
  default     = false
}
