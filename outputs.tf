output "databricks_workspace_details" {
  value = { for k in azurerm_databricks_workspace.this : k.name => {
    id                        = ws.id
    disk_encryption_set_id    = ws.disk_encryption_set_id
    managed_disk_identity     = ws.managed_disk_identity
    managed_resource_group_id = ws.managed_resource_group_id
    workspace_url             = ws.workspace_url
    workspace_id              = ws.workspace_id
    storage_account_identity  = ws.storage_account_identity
  } }
}
