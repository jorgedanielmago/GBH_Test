output "vnet_id" {
  value = azurerm_virtual_network.vcf_sandbox.id
}

output "site1_subnet_prefix" {
  value = local.site1_subnet_prefix
}

output "site2_subnet_prefix" {
  value = local.site2_subnet_prefix
}

output "witness_subnet_prefix" {
  value = local.witness_subnet_prefix
}

output "site1_host_ips" {
  value = { for k, m in module.site1_hosts : k => m.nic_private_ip }
}

output "site2_host_ips" {
  value = { for k, m in module.site2_hosts : k => m.nic_private_ip }
}

output "witness_host_ip" {
  value = var.deploy_witness ? module.witness_host[0].nic_private_ip : null
}

output "lab_host_public_ip" {
  value = var.deploy_lab_host ? module.lab_host[0].public_ip : null
}

output "lab_host_private_ip" {
  value = var.deploy_lab_host ? module.lab_host[0].nic_private_ip : null
}
