terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  skip_provider_registration = true

  subscription_id = var.azure_subscription_id
  features {}
}

variable "azure_subscription_id" {}

variable "location" {
  default = "eastus"
  type    = string
}
variable "username" {
  default = "lab_admin"
  type    = string
}
variable "password" {
  type      = string
  sensitive = true
}

data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

resource "azurerm_resource_group" "this" {
  name     = "rg-az800lab"
  location = var.location
}

resource "azurerm_virtual_network" "lab" {
  name                = "vnet-lab-eus"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "snet_lab1" {
  name                 = "snet-lab1"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.lab.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_public_ip" "public" {
  name                = "pip-connect"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_security_group" "rdp" {
  name                = "nsg-mgmt-p1"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
}

resource "azurerm_network_security_rule" "from_source" {
  name                        = "mgmt-p1-rdp-source"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = "${trimspace(data.http.myip.body)}/32"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_range      = "3389"
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.rdp.name
}
data "azurerm_public_ip" "this" {
  name                = azurerm_public_ip.public.name
  resource_group_name = azurerm_resource_group.this.name
}
output "connect_ip" {
  value = data.azurerm_public_ip.this.ip_address
}
