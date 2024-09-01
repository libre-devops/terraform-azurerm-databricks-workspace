resource "azurerm_databricks_workspace" "this" {
  for_each = { for k, v in var.databricks_workspaces : k => v }


  name                = each.value.name
  resource_group_name = var.rg_name
  location            = var.location
  tags                = var.tags
  sku                 = lower(each.value.sku)

  load_balancer_backend_address_pool_id = each.value.load_balancer_backend_address_pool_id
  managed_services_cmk_key_vault_key_id = each.value.managed_services_cmk_key_vault_key_id
  managed_disk_cmk_key_vault_key_id     = try(each.value.managed_disk_cmk_key_vault_key_id, null)
  #   managed_disk_cmk_rotation_to_latest_version_enabled = each.value.managed_disk_cmk_rotation_to_latest_version_enabled
  customer_managed_key_enabled          = each.value.customer_managed_key_enabled
  infrastructure_encryption_enabled     = lower(each.value.sku) == "premium" ? each.value.infrastructure_encryption_enabled : false
  public_network_access_enabled         = each.value.public_network_access_enabled
  network_security_group_rules_required = each.value.network_security_group_rules_required

  dynamic "custom_parameters" {
    for_each = each.value.custom_parameters != null ? [each.value.custom_parameters] : []
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
      vnet_address_prefix                                  = custom_parameters.value.vnet_address_prefix
    }
  }
}

resource "azurerm_databricks_virtual_network_peering" "example" {
  for_each            = { for k, v in var.databricks_workspaces : k => v if v.create_vnet_peering == true }
  name                = each.value.vnet_peering_name != null ? each.value.vnet_peering_name : "${azurerm_databricks_workspace.this[each.key].name}-peering"
  resource_group_name = var.rg_name
  workspace_id        = azurerm_databricks_workspace.this[each.key].id

  remote_address_space_prefixes = each.value.remote_address_space_prefixes
  remote_virtual_network_id     = each.value.remote_virtual_network_id
  allow_virtual_network_access  = each.value.allow_virtual_network_access
  allow_forwarded_traffic       = each.value.allow_forwarded_traffic
  allow_gateway_transit         = each.value.allow_gateway_transit
  use_remote_gateways           = each.value.use_remote_gateways
}

resource "azurerm_databricks_access_connector" "access_connector" {
  for_each            = { for k, v in var.databricks_workspaces : k => v if v.create_access_connector == true }
  name                = each.value.access_connector_name != null ? each.value.access_connector_name : "${azurerm_databricks_workspace.this[each.key].name}-access-connector"
  resource_group_name = var.rg_name
  location            = var.location
  tags                = var.tags

  dynamic "identity" {
    for_each = each.value.identity_type == "SystemAssigned" ? [each.value.identity_type] : []
    content {
      type = each.value.identity_type
    }
  }

  dynamic "identity" {
    for_each = each.value.identity_type == "UserAssigned" ? [each.value.identity_type] : []
    content {
      type         = each.value.identity_type
      identity_ids = length(try(each.value.identity_ids, [])) > 0 ? each.value.identity_ids : []
    }
  }
}