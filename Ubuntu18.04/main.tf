provider "azurerm" {
  version = "~>2.0"
  features {}
}

resource "azurerm_resource_group" "sample-rg" {
  name     = "sample-rg"
  location = "Japan East"
}

resource "azurerm_virtual_network" "sample-vnet" {
  name                = "sample-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.sample-rg.location
  resource_group_name = azurerm_resource_group.sample-rg.name
}

resource "azurerm_subnet" "sample-subnet" {
  name                 = "sample-subnet"
  resource_group_name  = azurerm_resource_group.sample-rg.name
  virtual_network_name = azurerm_virtual_network.sample-vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "sample-public-ip" {
  name                = "sample-public-ip"
  location            = azurerm_resource_group.sample-rg.location
  resource_group_name = azurerm_resource_group.sample-rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_security_group" "sample-sg" {
  name                = "sample-sg"
  location            = azurerm_resource_group.sample-rg.location
  resource_group_name = azurerm_resource_group.sample-rg.name

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

resource "azurerm_network_interface" "sample-vnic" {
  name                = "sample-vnic"
  location            = azurerm_resource_group.sample-rg.location
  resource_group_name = azurerm_resource_group.sample-rg.name

  ip_configuration {
    name                          = "myNicConfiguration"
    subnet_id                     = azurerm_subnet.sample-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.sample-public-ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "network_interface_security_group_association" {
  network_interface_id      = azurerm_network_interface.sample-vnic.id
  network_security_group_id = azurerm_network_security_group.sample-sg.id
}

resource "azurerm_linux_virtual_machine" "sample-vm" {
  name                  = "sample-vm"
  resource_group_name   = azurerm_resource_group.sample-rg.name
  location              = azurerm_resource_group.sample-rg.location
  size                  = "Standard_B1MS"
  admin_username        = "adminuser"
  network_interface_ids = [azurerm_network_interface.sample-vnic.id]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}
