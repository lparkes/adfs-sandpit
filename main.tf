provider "azurerm" {
  features {}
}

locals {
  admin_username = "adminuser"
  admin_password = var.windows_admin_password
  sts_fqdn       = "adfs-sandpit.${var.dns_zone}"
  #sts_fqdn      = azurerm_public_ip.adfs-sandpit.fqdn
}

resource "azurerm_resource_group" "sandpit" {
  name     = "sandpit"
  location = "Australia East"
}

resource "azurerm_virtual_network" "sandpit" {
  name                = "sandpit"
  address_space       = ["10.123.45.0/24"]
  location            = azurerm_resource_group.sandpit.location
  resource_group_name = azurerm_resource_group.sandpit.name
}

resource "azurerm_subnet" "sandpit" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.sandpit.name
  virtual_network_name = azurerm_virtual_network.sandpit.name
  address_prefixes     = ["10.123.45.0/25"]
}

resource "azurerm_public_ip" "adfs-sandpit" {
  name                = "adfs-sandpit-public-ip"
  resource_group_name = azurerm_resource_group.sandpit.name
  location            = azurerm_resource_group.sandpit.location
  allocation_method   = "Static"
  #domain_name_label   = "adfs-sandpit"
}

resource "azurerm_network_interface" "adfs" {
  name                = "adfs-nic"
  location            = azurerm_resource_group.sandpit.location
  resource_group_name = azurerm_resource_group.sandpit.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sandpit.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.adfs-sandpit.id
  }
}

resource "azurerm_windows_virtual_machine" "adfs" {
  name                = "adfs-sandpit"
  resource_group_name = azurerm_resource_group.sandpit.name
  location            = azurerm_resource_group.sandpit.location
  size                = "Standard_DS1_V2"
  admin_username      = local.admin_username
  admin_password      = local.admin_password
  
  network_interface_ids = [
    azurerm_network_interface.adfs.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  secret {
    key_vault_id = azurerm_key_vault.sandpit.id
    certificate {
      store = "My"
      url   = azurerm_key_vault_certificate.example.secret_id
    }
  }

  winrm_listener {
    protocol        = "Https"
    certificate_url = azurerm_key_vault_certificate.example.secret_id
  }
}

## Security stuff for the https winrm
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "sandpit" {
  name                        = "sandpit"
  location                    = azurerm_resource_group.sandpit.location
  resource_group_name         = azurerm_resource_group.sandpit.name
  enabled_for_disk_encryption = true
  enabled_for_deployment      = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_enabled         = true
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = var.vault_access_principal # data.azurerm_client_config.current.object_id


    certificate_permissions = [
      "create",
      "delete",
      "deleteissuers",
      "get",
      "getissuers",
      "import",
      "list",
      "listissuers",
      "managecontacts",
      "manageissuers",
      "setissuers",
      "update",
      "recover",
    ]

    key_permissions = [
      "backup",
      "create",
      "decrypt",
      "delete",
      "encrypt",
      "get",
      "import",
      "list",
      "purge",
      "recover",
      "restore",
      "sign",
      "unwrapKey",
      "update",
      "verify",
      "wrapKey",
    ]

    secret_permissions = [
      "backup",
      "delete",
      "get",
      "list",
      "purge",
      "recover",
      "restore",
      "set",
    ]

    storage_permissions = [
      "get",
    ]
  }

#  network_acls {
#    default_action = "Deny"
#    bypass         = "AzureServices"
#  }
}

resource "azurerm_key_vault_certificate" "example" {
  name         = "adfs-cert2"
  key_vault_id = azurerm_key_vault.sandpit.id

  # certificate_policy {
  #   issuer_parameters {
  #     name = "Self"
  #   }

  #   key_properties {
  #     exportable = true
  #     key_size   = 2048
  #     key_type   = "RSA"
  #     reuse_key  = true
  #   }

  #   lifetime_action {
  #     action {
  #       action_type = "AutoRenew"
  #     }

  #     trigger {
  #       days_before_expiry = 30
  #     }
  #   }

  #   secret_properties {
  #     content_type = "application/x-pkcs12"
  #   }

  #   x509_certificate_properties {
  #     # Server Authentication = 1.3.6.1.5.5.7.3.1
  #     # Client Authentication = 1.3.6.1.5.5.7.3.2
  #     extended_key_usage = ["1.3.6.1.5.5.7.3.1"]

  #     key_usage = [
  #       "cRLSign",
  #       "dataEncipherment",
  #       "digitalSignature",
  #       "keyAgreement",
  #       "keyCertSign",
  #       "keyEncipherment",
  #     ]

  #     subject_alternative_names {
  #       dns_names = [azurerm_public_ip.adfs-sandpit.fqdn]
  #     }

  #     subject            = "CN=${azurerm_public_ip.adfs-sandpit.fqdn}"
  #     validity_in_months = 12
  #   }
  # }
  
  certificate {
    contents = acme_certificate.sandpit.certificate_p12
    password = acme_certificate.sandpit.certificate_p12_password
  }

  certificate_policy {
    issuer_parameters {
      name = "Unknown"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = false
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }
  }  
}

resource "null_resource" "winrm" {

  depends_on = [azurerm_windows_virtual_machine.adfs]

  provisioner "local-exec" {
    command = "az vm run-command invoke  --command-id RunPowerShellScript --name adfs-sandpit -g sandpit --scripts @winrm.ps1"
  }
}

# resource "null_resource" "adfs" {
# ## Setup ADFS

# depends_on = [null_resource.winrm]

# provisioner "file" {
#   source      = "ADDS-Setup.ps1"
#   destination = "C:/Windows/Temp/ADDS-Setup.ps1"
#   connection {
#     type     = "winrm"
#     user     = local.admin_username
#     password = local.admin_password
#     port     = 5986
#     https    = true
#     insecure = true
#     host     = local.sts_fqdn
#   }
# }

# provisioner "remote-exec" {
#   inline = [         
#     "powershell.exe -ExecutionPolicy Bypass -File C:/Windows/Temp/ADDS-Setup.ps1"
#   ]
#   connection {
#     type     = "winrm"
#     user     = local.admin_username
#     password = local.admin_password
#     port     = 5986
#     https    = true
#     insecure = true
#     host     = local.sts_fqdn
#     timeout  = "20m"
#   }
# }
# }


## Bastion stuff from here
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.sandpit.name
  virtual_network_name = azurerm_virtual_network.sandpit.name
  address_prefixes     = ["10.123.45.128/27"]
}

resource "azurerm_public_ip" "bastion" {
  name                = "sandpit-bastion-ip"
  resource_group_name = azurerm_resource_group.sandpit.name
  location            = azurerm_resource_group.sandpit.location
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_bastion_host" "bastion" {
  name                = "Sandpit_Bastion"
  location            = azurerm_resource_group.sandpit.location
  resource_group_name = azurerm_resource_group.sandpit.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}


# Add-KdsRootKey -EffectiveTime (Get-Date).AddHours(-10)

# Import-Module ActiveDirectory

# New-ADUser ...

# Import-Module ADFS

#Install-AdfsFarm `
#-CertificateThumbprint:"${azurerm_key_vault_certificate.example.thumbprint}" `
#-FederationServiceDisplayName:"The Sandpit" `
#-FederationServiceName:"adfs-sandpit.australiaeast.cloudapp.azure.com" `
#-GroupServiceAccountIdentifier:"SANDPIT\adfs`$"
