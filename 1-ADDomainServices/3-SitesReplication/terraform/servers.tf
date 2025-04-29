

locals {
  servers = [
    {
      name       = "APEXDC1"
      ip         = "10.0.0.4"
      size       = "Standard_B2s"
      image_plan = "2022-datacenter-g2"
    },
    {
      name        = "APEXDC2"
      domain      = "apex.local"
      dns_servers = ["10.0.0.4"]
      features = [
        "AD-Domain-Services",
        "DNS"
      ]
      subnet_id  = azurerm_subnet.snet_lab2.id
      ip         = "10.0.1.6"
      size       = "Standard_B2s"
      image_plan = "2022-datacenter-g2"
    },
    {
      name        = "APEXDC3"
      domain      = "apex.local"
      dns_servers = ["10.0.0.4"]
      features = [
        "AD-Domain-Services",
        "DNS"
      ]
      subnet_id  = azurerm_subnet.snet_lab3.id
      ip         = "10.0.3.6"
      size       = "Standard_B2s"
      image_plan = "2022-datacenter-g2"
    }

  ]
}

module "first_server" {
  source   = "Azure/virtual-machine/azurerm"
  version  = "1.1.0"
  for_each = { for server in [local.servers[0]] : server.name => server }

  location            = var.location
  resource_group_name = azurerm_resource_group.this.name

  name           = each.key
  image_os       = "windows"
  size           = each.value.size
  subnet_id      = try(each.value.subnet_id, azurerm_subnet.snet_lab1.id)
  admin_username = var.username
  admin_password = var.password

  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  allow_extension_operations = true

  source_image_reference = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = each.value.image_plan
    version   = "latest"
  }

  data_disks = try(each.value.data_disks, null)

  new_boot_diagnostics_storage_account = {
    name = "boot${lower(replace(each.key, "-", ""))}"
  }
  new_network_interface = {
    name = "${each.key}-nic"
    ip_configurations = [
      {
        private_ip_address_allocation = "Static"
        private_ip_address            = each.value.ip
        primary                       = true
        public_ip_address_id          = azurerm_public_ip.public.id
      },
    ]
  }
}

module "remaining_servers" {
  source   = "Azure/virtual-machine/azurerm"
  version  = "1.1.0"
  for_each = { for server in slice(local.servers, 1, length(local.servers)) : server.name => server }

  location            = var.location
  resource_group_name = azurerm_resource_group.this.name

  name           = each.key
  image_os       = "windows"
  size           = each.value.size
  subnet_id      = try(each.value.subnet_id, azurerm_subnet.snet_lab1.id)
  admin_username = var.username
  admin_password = var.password

  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  allow_extension_operations = true

  source_image_reference = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = each.value.image_plan
    version   = "latest"
  }

  data_disks = try(each.value.data_disks, null)

  new_boot_diagnostics_storage_account = {
    name = "boot${lower(replace(each.key, "-", ""))}"
  }
  new_network_interface = {
    name        = "${each.key}-nic"
    dns_servers = try(each.value.dns_servers, null)
    ip_configurations = [
      {
        private_ip_address_allocation = "Static"
        private_ip_address            = each.value.ip
      }
    ]
  }
}

resource "azurerm_virtual_machine_extension" "setup_domain" {
  name                       = "setup_ad"
  virtual_machine_id         = module.first_server[local.servers[0].name].vm_id
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.19"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
{
  "ModulesUrl": "https://raw.githubusercontent.com/DanZab/az800/main/scripts/dsc/addomain.zip",
  "ConfigurationFunction": "addomain.ps1\\addomain",
  "Properties": {
    "DomainName": "apex.local",
    "AdminCreds": {
      "UserName": "${var.username}",
      "Password": "PrivateSettingsRef:AdminPassword"
    },
    "ConfigScript": "https://raw.githubusercontent.com/DanZab/az800/main/scripts/apex.txt"
  }
}
SETTINGS

  protected_settings = <<PROT_SETTINGS
{
  "Items": {
    "AdminPassword": "${var.password}"
  }
}
PROT_SETTINGS
}


resource "azurerm_virtual_machine_extension" "domain_join" {
  for_each = { for server in local.servers : server.name => server if try(server.domain != null, false) }

  name                       = "join-domain"
  virtual_machine_id         = module.remaining_servers[each.key].vm_id
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
        {
            "Name": "${each.value.domain}",
            "User": "${var.username}@${each.value.domain}",
            "Restart": "true",
            "Options": "3"
        }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
        {
            "Password": "${var.password}"
        }
PROTECTED_SETTINGS

  depends_on = [azurerm_virtual_machine_extension.setup_domain]
}

resource "azurerm_virtual_machine_extension" "add_features" {
  for_each = { for server in local.servers : server.name => server if try(server.features != null, false) }

  name                       = "add-features"
  virtual_machine_id         = module.remaining_servers[each.key].vm_id
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.19"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
{
  "ModulesUrl": "https://raw.githubusercontent.com/DanZab/az800/main/scripts/dsc/add-features.zip",
  "ConfigurationFunction": "add-features.ps1\\add-features",
  "Properties": {
    "Features": ${jsonencode(each.value.features)}
  }
}
SETTINGS

  depends_on = [azurerm_virtual_machine_extension.setup_domain]
}
