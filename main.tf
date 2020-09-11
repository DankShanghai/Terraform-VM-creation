# Konfiguracja providera chmury
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }
}

provider "azurerm" {
  features {}
}

# Tworzenie sieci wirtualnej
resource "azurerm_virtual_network" "vnet" {
    name                = "myTFVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "West Europe"
    resource_group_name = azurerm_resource_group.rg.name
}

# Resource group
resource "azurerm_resource_group" "rg" {
  name     = "testTFGroup"
  location = "West Europe"
}


# Tworzenie subnetu
resource "azurerm_subnet" "subnet" {
  name                 = "myTFSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Tworzenie publicznego IP
resource "azurerm_public_ip" "publicip" {
  name                = "myTFPublicIP"
  location            = "West Europe"
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}


# Tworzenie grupy security i rules
resource "azurerm_network_security_group" "nsg" {
  name                = "myTFNSG"
  location            = "West Europe"
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Tworzenie network interface
resource "azurerm_network_interface" "nic" {
  name                      = "myNIC"
  location                  = "West Europe"
  resource_group_name       = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "myNICConfg"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip.id
  }
}

# Tworzenie Windows Server virtual machine
resource "azurerm_virtual_machine" "testTFVM" {
  name                  = "testTFVM-1"
  location              = "West Europe"
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = "Standard_F2"

  storage_os_disk {
   name              = "myOsDisk"
   caching           = "ReadWrite"
   create_option     = "FromImage"
   managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-datacenter"
    version   = "latest"
  }

  os_profile {
    computer_name  = "testTFVM"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_windows_config {
    
  }
}

data "azurerm_public_ip" "ip" {
  name                = azurerm_public_ip.publicip.name
  resource_group_name = azurerm_virtual_machine.testTFVM.resource_group_name
  depends_on          = [azurerm_virtual_machine.testTFVM]
}
