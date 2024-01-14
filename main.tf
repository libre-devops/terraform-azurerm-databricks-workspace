resource "azurerm_databricks_workspace" "this" {
  for_each = { for k, v in var.databricks_workspaces : k => v }


  name                = each.value.name
  resource_group_name = var.rg_name
  location            = var.location
  tags                = var.tags
  sku                 = lower(each.value.sku)

  load_balancer_backend_address_pool_id               = each.value.load_balancer_backend_address_pool_id
  managed_services_cmk_key_vault_key_id               = each.value.managed_services_cmk_key_vault_key_id
  managed_disk_cmk_key_vault_key_id                   = each.value.managed_disk_cmk_key_vault_key_id
  managed_disk_cmk_rotation_to_latest_version_enabled = each.value.managed_disk_cmk_rotation_to_latest_version_enabled
  customer_managed_key_enabled                        = each.value.customer_managed_key_enabled
  infrastructure_encryption_enabled                   = lower(each.value.sku) == "premium" ? each.value.infrastructure_encryption_enabled : false
  public_network_access_enabled                       = each.value.public_network_access_enabled
  network_security_group_rules_required               = each.value.network_security_group_rules_required

  dynamic "custom_parameters" {
    for_each = each.value.custom_parameters != null ? each.value.custom_parameters : {}
    content {
      machine_learning_workspace_id                        = custom_parameters.value.machine_learning_workspace_id
      nat_gateway_name                                     = custom_parameters.value.nat_gateway_name
      public_ip_name                                       = custom_parameters.value.public_ip_name
      no_public_ip                                         = custom_parameters.value.no_public_ip
      public_subnet_name                                   = custom_parameters.value.public_subnet_name
      public_subnet_network_security_group_association_id  = custom_parameters.value.public_subnet_network_security_group_association_id
      private_subnet_name                                  = custom_parameters.value.private_subnet_name
      private_subnet_network_security_group_association_id = custom_parameters.value.private_subnet_network_security_group_association_id
      storage_account_name                                 = custom_parameters.value.storage_account_name
      storage_account_sku_name                             = custom_parameters.value.storage_account_sku_name
      virtual_network_id                                   = custom_parameters.value.virtual_network_id
    }
  }
}
