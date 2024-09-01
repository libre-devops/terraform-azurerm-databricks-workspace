output "databricks_access_connector_details" {
  value = {
    for k, v in azurerm_databricks_access_connector.access_connector : k => {
      id = v.id
      identity = length(v.identity) > 0 ? [
        for id_block in v.identity : {
          type         = id_block.type
          principal_id = id_block.principal_id
          tenant_id    = id_block.tenant_id
          identity_ids = try(id_block.identity_ids, [])
        }
      ] : []
    }
  }
}

output "databricks_virtual_network_peering_details" {
  value = {
    for k, v in azurerm_databricks_virtual_network_peering.example : k => {
      id = v.id
    }
  }
}

output "databricks_workspace_details" {
  value = {
    for k, v in azurerm_databricks_workspace.this : k => {
      id                     = v.id
      disk_encryption_set_id = v.disk_encryption_set_id
      managed_disk_identity = length(v.managed_disk_identity) > 0 ? {
        principal_id = v.managed_disk_identity[0].principal_id
        tenant_id    = v.managed_disk_identity[0].tenant_id
        type         = v.managed_disk_identity[0].type
      } : null
      managed_resource_group_id = v.managed_resource_group_id
      workspace_url             = v.workspace_url
      workspace_id              = v.workspace_id
      storage_account_identity = length(v.storage_account_identity) > 0 ? {
        principal_id = v.storage_account_identity[0].principal_id
        tenant_id    = v.storage_account_identity[0].tenant_id
        type         = v.storage_account_identity[0].type
      } : null
    }
  }
}
