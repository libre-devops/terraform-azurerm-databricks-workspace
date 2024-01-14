output "databricks_workspace_details" {
  value = { for k in azurerm_databricks_workspace.this : k.name => {
    id                        = k.id
    disk_encryption_set_id    = k.disk_encryption_set_id
    managed_disk_identity     = k.managed_disk_identity
    managed_resource_group_id = k.managed_resource_group_id
    workspace_url             = k.workspace_url
    workspace_id              = k.workspace_id
    storage_account_identity  = k.storage_account_identity
  } }
}
