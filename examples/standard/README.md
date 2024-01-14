```hcl
module "rg" {
  source = "cyber-scot/rg/azurerm"

  name     = "rg-${var.short}-${var.loc}-${var.env}-01"
  location = local.location
  tags     = local.tags
}

module "network" {
  source = "cyber-scot/network/azurerm"

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  vnet_name          = "vnet-${var.short}-${var.loc}-${var.env}-01"
  vnet_location      = module.rg.rg_location
  vnet_address_space = ["10.0.0.0/16"]

  subnets = {
    "sn1-public-${module.network.vnet_name}" = {
      address_prefixes = ["10.0.0.0/24"]
      delegation = [
        {
          type = "Microsoft.Databricks/workspaces"
        },
      ]
    }
    "sn2-private-${module.network.vnet_name}" = {
      address_prefixes = ["10.0.1.0/24"]
      delegation = [
        {
          type = "Microsoft.Databricks/workspaces"
        },
      ]
    }
  }
}

module "public_nsg" {
  source = "cyber-scot/nsg/azurerm"

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  nsg_name              = "nsg-public-${var.short}-${var.loc}-${var.env}-01"
  associate_with_subnet = true
  subnet_id             = module.network.subnets_ids["sn1-public-${module.network.vnet_name}"]
}

module "private_nsg" {
  source = "cyber-scot/nsg/azurerm"

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  nsg_name              = "nsg-private-${var.short}-${var.loc}-${var.env}-01"
  associate_with_subnet = true
  subnet_id             = module.network.subnets_ids["sn2-private-${module.network.vnet_name}"]
}

module "databricks" {
  source = "../../"

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  databricks_workspaces = [
    {
      name                                  = "db-${var.short}-${var.loc}-${var.env}-01"
      sku                                   = "trial"
      customer_managed_key_enabled          = false
      infrastructure_encryption_enabled     = false
      public_network_access_enabled         = false
      network_security_group_rules_required = "NoAzureDatabricksRules"

      custom_parameters = {
        no_public_ip                                         = true
        virtual_network_id                                   = module.network.vnet_id
        storage_account_name                                 = "sadb${var.short}${var.loc}${var.env}01"
        storage_account_sku_name                             = "Standard_LRS"
        public_subnet_name                                   = "sn1-public-${module.network.vnet_name}"
        public_subnet_network_security_group_association_id  = module.public_nsg.nsg_subnet_association_ids[0]
        private_subnet_name                                  = "sn2-private-${module.network.vnet_name}"
        private_subnet_network_security_group_association_id = module.private_nsg.nsg_subnet_association_ids[0]
      }
    }
  ]
}
```
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 3.87.0 |
| <a name="provider_external"></a> [external](#provider\_external) | 2.3.2 |
| <a name="provider_http"></a> [http](#provider\_http) | 3.4.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_databricks"></a> [databricks](#module\_databricks) | ../../ | n/a |
| <a name="module_network"></a> [network](#module\_network) | cyber-scot/network/azurerm | n/a |
| <a name="module_private_nsg"></a> [private\_nsg](#module\_private\_nsg) | cyber-scot/nsg/azurerm | n/a |
| <a name="module_public_nsg"></a> [public\_nsg](#module\_public\_nsg) | cyber-scot/nsg/azurerm | n/a |
| <a name="module_rg"></a> [rg](#module\_rg) | cyber-scot/rg/azurerm | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [external_external.detect_os](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [external_external.generate_timestamp](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [http_http.client_ip](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_Regions"></a> [Regions](#input\_Regions) | Converts shorthand name to longhand name via lookup on map list | `map(string)` | <pre>{<br>  "eus": "East US",<br>  "euw": "West Europe",<br>  "uks": "UK South",<br>  "ukw": "UK West"<br>}</pre> | no |
| <a name="input_env"></a> [env](#input\_env) | The env variable, for example - prd for production. normally passed via TF\_VAR. | `string` | `"prd"` | no |
| <a name="input_loc"></a> [loc](#input\_loc) | The loc variable, for the shorthand location, e.g. uks for UK South.  Normally passed via TF\_VAR. | `string` | `"uks"` | no |
| <a name="input_short"></a> [short](#input\_short) | The shorthand name of to be used in the build, e.g. cscot for CyberScot.  Normally passed via TF\_VAR. | `string` | `"cscot"` | no |
| <a name="input_static_tags"></a> [static\_tags](#input\_static\_tags) | The tags variable | `map(string)` | <pre>{<br>  "Contact": "info@cyber.scot",<br>  "CostCentre": "671888",<br>  "ManagedBy": "Terraform"<br>}</pre> | no |

## Outputs

No outputs.
