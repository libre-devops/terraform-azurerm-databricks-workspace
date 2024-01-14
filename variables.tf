variable "databricks_workspaces" {
  description = "The databricks workspaces to create"
  type = list(object({
    name                                                = string
    sku                                                 = string
    load_balancer_backend_address_pool_id               = optional(string)
    managed_services_cmk_key_vault_key_id               = optional(string)
    managed_disk_cmk_key_vault_key_id                   = optional(string)
    managed_disk_cmk_rotation_to_latest_version_enabled = optional(bool)
    customer_managed_key_enabled                        = optional(bool)
    infrastructure_encryption_enabled                   = optional(bool)
    public_network_access_enabled                       = optional(bool, false)
    network_security_group_rules_required               = optional(string)
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
