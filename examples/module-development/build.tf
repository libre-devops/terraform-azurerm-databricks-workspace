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
  subnet_id             = module.network.subnets_ids["private"]
  custom_nsg_rules = {
    "AllowVnetInbound" = {
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    }
  }
}

module "public_nsg" {
  source = "libre-devops/nsg/azurerm"

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  nsg_name              = "nsg-public-${var.short}-${var.loc}-${var.env}-01"
  associate_with_subnet = true
  subnet_id             = module.network.subnets_ids["public"]
  custom_nsg_rules = {
    "AllowVnetInbound" = {
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
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


resource "azurerm_databricks_access_connector" "example" {
  name                = "databricks-test"
  resource_group_name = module.rg.rg_name
  location            = module.rg.rg_location
  tags                = module.rg.rg_tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.test.id]
  }
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
    }
  ]
}
