```hcl
module "rg" {
  source = "libre-devops/rg/azurerm"

  rg_name  = "rg-${var.short}-${var.loc}-${var.env}-01"
  location = local.location
  tags     = local.tags
}

module "network" {
  source = "libre-devops/network/azurerm"

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  vnet_name          = "vnet-${var.short}-${var.loc}-${var.env}-01"
  vnet_location      = module.rg.rg_location
  vnet_address_space = ["10.0.0.0/16"]

  subnets = {
    "subnet1" = {
      address_prefixes  = ["10.0.3.0/24"]
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
      delegation        = []
    },
    "private" = {
      address_prefixes  = ["10.0.4.0/24"]
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
      delegation = [
        {
          type = "Microsoft.Databricks/workspaces"
        }
      ]
    },
    "public" = {
      address_prefixes  = ["10.0.5.0/24"]
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
      delegation = [
        {
          type = "Microsoft.Databricks/workspaces"
        }
      ]
    }
  }
}

module "private_nsg" {
  source = "libre-devops/nsg/azurerm"

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  nsg_name              = "nsg-private-${var.short}-${var.loc}-${var.env}-01"
  associate_with_subnet = true
  apply_standard_rules  = false
  subnet_id             = module.network.subnets_ids["private"]
  custom_nsg_rules      = {}
}

module "public_nsg" {
  source = "libre-devops/nsg/azurerm"

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  nsg_name              = "nsg-public-${var.short}-${var.loc}-${var.env}-01"
  associate_with_subnet = true
  subnet_id             = module.network.subnets_ids["public"]
  apply_standard_rules  = false

  custom_nsg_rules = {}
}

module "sa" {
  source = "libre-devops/storage-account/azurerm"
  storage_accounts = [
    {
      name     = "sa${var.short}${var.loc}${var.env}01"
      rg_name  = module.rg.rg_name
      location = module.rg.rg_location
      tags     = module.rg.rg_tags

      identity_type = "SystemAssigned"
      identity_ids  = []

      network_rules = {
        bypass                     = ["AzureServices"]
        default_action             = "Deny"
        ip_rules                   = [chomp(data.http.client_ip.response_body)]
        virtual_network_subnet_ids = []
      }
    },
  ]
}

module "role_assignments" {
  source = "libre-devops/role-assignment/azurerm"

  assignments = [
    {
      role_definition_name = "Key Vault Administrator"
      scope                = module.rg.rg_id
      principal_id         = data.azurerm_client_config.current.object_id
    },
    {
      role_definition_name = "Storage Blob Data Owner"
      scope                = module.rg.rg_id
      principal_id         = azurerm_user_assigned_identity.test.principal_id
    },
  ]
}

module "key_vault" {
  source = "libre-devops/keyvault/azurerm"

  key_vaults = [
    {
      name     = "kv-${var.short}-${var.loc}-${var.env}-tst-01"
      rg_name  = module.rg.rg_name
      location = module.rg.rg_location
      tags     = module.rg.rg_tags
      contact = [
        {
          name  = "LibreDevOps"
          email = "info@libredevops.org"
        }
      ]
      enabled_for_deployment          = true
      enabled_for_disk_encryption     = true
      enabled_for_template_deployment = true
      enable_rbac_authorization       = true
      purge_protection_enabled        = false
      public_network_access_enabled   = true
      network_acls = {
        default_action             = "Deny"
        bypass                     = "AzureServices"
        ip_rules                   = [chomp(data.http.client_ip.response_body)]
        virtual_network_subnet_ids = [module.network.subnets_ids["subnet1"]]
      }
    }
  ]
}

resource "azurerm_user_assigned_identity" "test" {
  location            = module.rg.rg_location
  name                = "test-uid-db"
  resource_group_name = module.rg.rg_name
  tags                = module.rg.rg_tags
}

module "databricks_workspace" {
  source = "../../"

  depends_on = [module.role_assignments]

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  databricks_workspaces = [
    {
      name                                  = "datab-${var.short}-${var.loc}-${var.env}-01"
      sku                                   = "standard"
      customer_managed_key_enabled          = false
      infrastructure_encryption_enabled     = false
      public_network_access_enabled         = true
      network_security_group_rules_required = "AllRules" # Use Default rules or any other supported rule

      custom_parameters = {
        public_ip_name                                       = "pip-datab-${var.short}-${var.loc}-${var.env}-01"
        no_public_ip                                         = false # Keep false to allow a public IP
        public_subnet_name                                   = "public"
        public_subnet_network_security_group_association_id  = module.public_nsg.nsg_id
        private_subnet_name                                  = "private"
        private_subnet_network_security_group_association_id = module.private_nsg.nsg_id
        storage_account_name                                 = "lbdotstdbsa1"
        storage_account_sku_name                             = "Standard_LRS"
        virtual_network_id                                   = module.network.vnet_id
        vnet_address_prefix                                  = module.network.vnet_address_space[0]
      }
      create_access_connector       = true
      create_vnet_peering           = false
      remote_virtual_network_id     = module.network.vnet_id
      remote_address_space_prefixes = toset([module.network.vnet_address_space[0]])
      allow_virtual_network_access  = true
      identity_type                 = "UserAssigned"
      identity_ids                  = [azurerm_user_assigned_identity.test.id]
    }
  ]
}
```
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 3.116.0 |
| <a name="provider_http"></a> [http](#provider\_http) | 3.4.4 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_databricks_workspace"></a> [databricks\_workspace](#module\_databricks\_workspace) | ../../ | n/a |
| <a name="module_key_vault"></a> [key\_vault](#module\_key\_vault) | libre-devops/keyvault/azurerm | n/a |
| <a name="module_network"></a> [network](#module\_network) | libre-devops/network/azurerm | n/a |
| <a name="module_private_nsg"></a> [private\_nsg](#module\_private\_nsg) | libre-devops/nsg/azurerm | n/a |
| <a name="module_public_nsg"></a> [public\_nsg](#module\_public\_nsg) | libre-devops/nsg/azurerm | n/a |
| <a name="module_rg"></a> [rg](#module\_rg) | libre-devops/rg/azurerm | n/a |
| <a name="module_role_assignments"></a> [role\_assignments](#module\_role\_assignments) | libre-devops/role-assignment/azurerm | n/a |
| <a name="module_sa"></a> [sa](#module\_sa) | libre-devops/storage-account/azurerm | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_user_assigned_identity.test](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
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
