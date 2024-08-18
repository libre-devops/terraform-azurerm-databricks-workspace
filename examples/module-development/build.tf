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
    }
  }
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


module "databricks_workspace" {
  source = "../../"

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags


  databricks_workspaces = [
    {
      name                                  = "datab-${var.short}-${var.loc}-${var.env}-01"
      sku                                   = "standard"
      customer_managed_key_enabled          = false
      infrastructure_encryption_enabled     = true
      public_network_access_enabled         = false
      network_security_group_rules_required = "NoAzureDatabricksRules"

      custom_parameters = {
        public_ip_name     = "pip-datab-${var.short}-${var.loc}-${var.env}-01"
        no_public_ip       = false
        public_subnet_name = "public"
        #         public_subnet_network_security_group_association_id  = "example-public-nsg-id"
        private_subnet_name = "private"
        #         private_subnet_network_security_group_association_id = "example-private-nsg-id"
        storage_account_name     = "lbdotstdbsa1"
        storage_account_sku_name = "Standard_LRS"
        virtual_network_id       = module.network.vnet_id
        vnet_address_prefix      = module.network.vnet_address_space[0]
      }
    }
  ]
}
