variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Name of the (pre-existing) resource group to deploy into"
  type        = string
  default     = "IT-SysAdmin-RG-4"
}

variable "admin_username" {
  description = "Admin username for the nested-virtualization VM shells"
  type        = string
  default     = "vcfadmin"
}

variable "admin_ssh_public_key" {
  description = "SSH public key for VM admin access"
  type        = string
  sensitive   = true
}

variable "vm_size" {
  description = "VM size — must support nested virtualization (Dv3/Dsv3/Ev3/Esv3 or newer)"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "witness_vm_size" {
  description = "VM size for the witness host — lighter than data hosts"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "hosts_per_site" {
  description = "Number of simulated ESXi hosts per site (2 recommended for time-boxed demo)"
  type        = number
  default     = 2
}

variable "deploy_witness" {
  description = "Deploy a separate Azure VM for the witness (not used in the KVM lab plan)"
  type        = bool
  default     = false
}

variable "deploy_lab_host" {
  description = "Deploy the single KVM lab host that runs nested ESXi/witness/vCenter"
  type        = bool
  default     = true
}

variable "lab_vm_size" {
  description = "Size of the KVM lab host (8 vCPUs fits a 9-vCPU quota; E-series preferred for RAM)"
  type        = string
  default     = "Standard_E8s_v3"
}

variable "admin_source_ip" {
  description = "Your public IP in CIDR form (e.g. 201.140.10.25/32) allowed to SSH into the lab host"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID that hosts the sandbox resource group"
  type        = string
}

variable "tenant_id" {
  description = "Microsoft Entra tenant ID"
  type        = string
}
