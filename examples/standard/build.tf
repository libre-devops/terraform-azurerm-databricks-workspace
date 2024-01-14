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
      network_security_group_rules_required = "AllRules"

      custom_parameters = {
        no_public_ip             = true
        virtual_network_id       = module.network.vnet_id
        storage_account_name     = "sadb${var.short}${var.loc}${var.env}01"
        storage_account_sku_name = "Standard_LRS"
        private_subnet_name      = "sn2-private-${module.network.vnet_name}"
        public_subnet_name       = "sn1-public-${module.network.vnet_name}"

      }
    }
  ]
}
