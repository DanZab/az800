

locals {
  servers = [
    {
      name       = "DC1"
      size       = "Standard_B2s"
      image_plan = "2022-datacenter-g2"
      data_disks = [{
        name                 = "DC1-DISK2"
        storage_account_type = "Standard_LRS"
        create_option        = "Empty"
        attach_setting = {
          lun     = 1
          caching = "ReadWrite"
        }
        disk_size_gb = 128
      }]
    },
    {
      name       = "DC2"
      size       = "Standard_B2s"
      image_plan = "2022-datacenter-g2"
    }
  ]

  domain_dn = join(",", [for el in split(".", var.domain_name) : "DC=${el}"])
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
        private_ip_address_allocation = "Dynamic"
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
      { private_ip_address_allocation = "Dynamic" }
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
  "ModulesUrl": "https://raw.githubusercontent.com/DanZab/az800/main/scripts/dsc/setup-domain.zip",
  "ConfigurationFunction": "setup-domain.ps1\\setup-domain",
  "Properties": {
    "DomainName": "${var.domain_name}",
    "AdminCreds": {
      "UserName": "${var.username}",
      "Password": "PrivateSettingsRef:AdminPassword"
    },
    "DomainDN": "${local.domain_dn}"
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
