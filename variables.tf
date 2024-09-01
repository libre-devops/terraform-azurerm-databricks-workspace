variable "databricks_workspaces" {
  description = "The databricks workspaces to create"
  type = list(object({
    name                                                = string
    sku                                                 = string
    load_balancer_backend_address_pool_id               = optional(string, null)
    managed_services_cmk_key_vault_key_id               = optional(string, null)
    managed_disk_cmk_key_vault_key_id                   = optional(string, null)
    managed_disk_cmk_rotation_to_latest_version_enabled = optional(bool, false)
    customer_managed_key_enabled                        = optional(bool, false)
    infrastructure_encryption_enabled                   = optional(bool, false)
    public_network_access_enabled                       = optional(bool, false)
    network_security_group_rules_required               = optional(string, "NoAzureDatabricksRules")
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
    create_vnet_peering           = optional(bool, false)
    vnet_peering_name             = optional(string)
    remote_address_space_prefixes = optional(list(string))
    remote_virtual_network_id     = optional(string)
    allow_virtual_network_access  = optional(bool)
    allow_forwarded_traffic       = optional(bool)
    allow_gateway_transit         = optional(bool)
    use_remote_gateways           = optional(bool)
    create_access_connector       = optional(bool, false)
    identity_type                 = optional(string)
    identity_ids                  = optional(list(string))
    access_connector_name         = optional(string)
  }))
}

variable "location" {
  description = "The location for this resource to be put in"
  type        = string
}

variable "rg_name" {
  description = "The name of the resource group, this module does not create a resource group, it is expecting the value of a resource group already exists"
  type        = string
}

variable "tags" {
  type        = map(string)
  description = "A map of the tags to use on the resources that are deployed with this module."
}
