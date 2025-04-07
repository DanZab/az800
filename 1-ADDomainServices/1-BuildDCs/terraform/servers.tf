

locals {
  servers = [
    {
      name       = "DC1"
      size       = "Standard_B2s"
      image_plan = "2022-datacenter-g2"
    },
    {
      name       = "DC2"
      size       = "Standard_B2s"
      image_plan = "2022-datacenter-g2"
    }
  ]
}

module "servers" {
  source   = "Azure/virtual-machine/azurerm"
  version  = "1.1.0"
  for_each = { for server in local.servers : server.name => server }

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
    name              = "${each.key}-nic"
    ip_configurations = [{ private_ip_address_allocation = "Dynamic" }]
  }
}
