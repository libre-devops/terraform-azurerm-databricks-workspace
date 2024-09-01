```hcl
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
| [azurerm_databricks_access_connector.access_connector](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/databricks_access_connector) | resource |
| [azurerm_databricks_virtual_network_peering.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/databricks_virtual_network_peering) | resource |
| [azurerm_databricks_workspace.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/databricks_workspace) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_databricks_workspaces"></a> [databricks\_workspaces](#input\_databricks\_workspaces) | The databricks workspaces to create | <pre>list(object({<br>    name                                                = string<br>    sku                                                 = string<br>    load_balancer_backend_address_pool_id               = optional(string, null)<br>    managed_services_cmk_key_vault_key_id               = optional(string, null)<br>    managed_disk_cmk_key_vault_key_id                   = optional(string, null)<br>    managed_disk_cmk_rotation_to_latest_version_enabled = optional(bool, false)<br>    customer_managed_key_enabled                        = optional(bool, false)<br>    infrastructure_encryption_enabled                   = optional(bool, false)<br>    public_network_access_enabled                       = optional(bool, false)<br>    network_security_group_rules_required               = optional(string, "NoAzureDatabricksRules")<br>    custom_parameters = optional(object({<br>      machine_learning_workspace_id                        = optional(string)<br>      nat_gateway_name                                     = optional(string)<br>      public_ip_name                                       = optional(string)<br>      no_public_ip                                         = optional(bool)<br>      public_subnet_name                                   = optional(string)<br>      public_subnet_network_security_group_association_id  = optional(string)<br>      private_subnet_name                                  = optional(string)<br>      private_subnet_network_security_group_association_id = optional(string)<br>      storage_account_name                                 = optional(string)<br>      storage_account_sku_name                             = optional(string)<br>      virtual_network_id                                   = optional(string)<br>      vnet_address_prefix                                  = optional(string)<br>    }))<br>    create_vnet_peering           = optional(bool, false)<br>    vnet_peering_name             = optional(string)<br>    remote_address_space_prefixes = optional(list(string))<br>    remote_virtual_network_id     = optional(string)<br>    allow_virtual_network_access  = optional(bool)<br>    allow_forwarded_traffic       = optional(bool)<br>    allow_gateway_transit         = optional(bool)<br>    use_remote_gateways           = optional(bool)<br>    create_access_connector       = optional(bool, false)<br>    identity_type                 = optional(string)<br>    identity_ids                  = optional(list(string))<br>    access_connector_name         = optional(string)<br>  }))</pre> | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | The location for this resource to be put in | `string` | n/a | yes |
| <a name="input_rg_name"></a> [rg\_name](#input\_rg\_name) | The name of the resource group, this module does not create a resource group, it is expecting the value of a resource group already exists | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of the tags to use on the resources that are deployed with this module. | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_databricks_access_connector_details"></a> [databricks\_access\_connector\_details](#output\_databricks\_access\_connector\_details) | n/a |
| <a name="output_databricks_virtual_network_peering_details"></a> [databricks\_virtual\_network\_peering\_details](#output\_databricks\_virtual\_network\_peering\_details) | n/a |
| <a name="output_databricks_workspace_details"></a> [databricks\_workspace\_details](#output\_databricks\_workspace\_details) | n/a |
