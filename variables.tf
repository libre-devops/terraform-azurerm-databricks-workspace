variable "databricks_workspaces" {
  description = "The databricks workspaces to create"
  type = list(object({
    name                                                = string
    sku                                                 = string
    rg_name                                             = string
    location                                            = optional(string, "uksouth")
    tags                                                = map(string)
    load_balancer_backend_address_pool_id               = optional(string, null)
    managed_services_cmk_key_vault_key_id               = optional(string, null)
    managed_disk_cmk_key_vault_key_id                   = optional(string, null)
    managed_disk_cmk_rotation_to_latest_version_enabled = optional(bool, false)
    customer_managed_key_enabled                        = optional(bool, false)
    infrastructure_encryption_enabled                   = optional(bool, false)
    public_network_access_enabled                       = optional(bool, false)
    network_security_group_rules_required               = optional(string, "NoAzureDatabricksRules")
    enhanced_security_compliance = optional(object({
      automatic_cluster_update_enabled      = optional(bool, false)
      compliance_security_profile_enabled   = optional(bool, false)
      compliance_security_profile_standards = optional(list(string))
      enhanced_security_monitoring_enabled  = optional(bool, false)
    }))
    custom_parameters = optional(object({
      machine_learning_workspace_id                        = optional(string)
      nat_gateway_name                                     = optional(string)
      public_ip_name                                       = optional(string)
      no_public_ip                                         = optional(bool)
      public_subnet_name                                   = optional(string)
      public_subnet_network_security_group_association_id  = optional(string)
      private_subnet_name                                  = optional(string)
      private_subnet_network_security_group_association_id = optional(string)
      storage_account_name                                 = optional(string)
      storage_account_sku_name                             = optional(string)
      virtual_network_id                                   = optional(string)
      vnet_address_prefix                                  = optional(string)
    }))
  }))
}
