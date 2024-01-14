```hcl
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
    }
  }
}
```
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_databricks_workspace.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/databricks_workspace) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_databricks_workspaces"></a> [databricks\_workspaces](#input\_databricks\_workspaces) | The databricks workspaces to create | <pre>list(object({<br>    name                                                = string<br>    sku                                                 = string<br>    load_balancer_backend_address_pool_id               = optional(string)<br>    managed_services_cmk_key_vault_key_id               = optional(string)<br>    managed_disk_cmk_key_vault_key_id                   = optional(string)<br>    managed_disk_cmk_rotation_to_latest_version_enabled = optional(bool)<br>    customer_managed_key_enabled                        = optional(bool)<br>    infrastructure_encryption_enabled                   = optional(bool)<br>    public_network_access_enabled                       = optional(bool, false)<br>    network_security_group_rules_required               = optional(string)<br>    custom_parameters = optional(object({<br>      machine_learning_workspace_id                        = optional(string)<br>      nat_gateway_name                                     = optional(string)<br>      public_ip_name                                       = optional(string)<br>      no_public_ip                                         = optional(bool)<br>      public_subnet_name                                   = optional(string)<br>      public_subnet_network_security_group_association_id  = optional(string)<br>      private_subnet_name                                  = optional(string)<br>      private_subnet_network_security_group_association_id = optional(string)<br>      storage_account_name                                 = optional(string)<br>      storage_account_sku_name                             = optional(string)<br>      virtual_network_id                                   = optional(string)<br>      vnet_address_prefix                                  = optional(string)<br>    }))<br>  }))</pre> | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | The location for this resource to be put in | `string` | n/a | yes |
| <a name="input_rg_name"></a> [rg\_name](#input\_rg\_name) | The name of the resource group, this module does not create a resource group, it is expecting the value of a resource group already exists | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of the tags to use on the resources that are deployed with this module. | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_databricks_workspace_details"></a> [databricks\_workspace\_details](#output\_databricks\_workspace\_details) | n/a |
