resource "azurerm_resource_group" "testing" {
  name     = "testRG"
  location = "central india"
}

resource "azurerm_virtual_network" "testing" {
  name                = "testing-vnet"
  resource_group_name = azurerm_resource_group.testing.name
  location            = azurerm_resource_group.testing.location
  address_space       = ["10.0.0.0/16"]

}

resource "azurerm_subnet" "testing" {
  name                 = "testing-subnet"
  resource_group_name  = azurerm_resource_group.testing.name
  virtual_network_name = azurerm_virtual_network.testing.name
  address_prefixes     = ["10.0.1.0/24"]

}


resource "azurerm_public_ip" "testing" {
  name                = "acceptanceTestPublicIp1"
  resource_group_name = azurerm_resource_group.testing.name
  location            = azurerm_resource_group.testing.location
  allocation_method   = "Static"
  sku                 = "Standard"
}


resource "azurerm_network_interface" "testing" {
  name                = "testing-nic"
  location            = azurerm_resource_group.testing.location
  resource_group_name = azurerm_resource_group.testing.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.testing.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "/subscriptions/dacf4b60-de1a-459b-a858-27b25d7d14ba/resourceGroups/testRG/providers/Microsoft.Network/publicIPAddresses/acceptanceTestPublicIp1"
  }
}


resource "azurerm_linux_virtual_machine" "testing" {
  name                            = "testing-machine"
  resource_group_name             = azurerm_resource_group.testing.name
  location                        = azurerm_resource_group.testing.location
  size                            = "Standard_F2"
  admin_username                  = "adminuser"
  admin_password                  = "Radhey@654321"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.testing.id,
  ]



  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}


resource "azurerm_network_security_group" "testing" {
  name                = "nsg1"
  location            = azurerm_resource_group.testing.location
  resource_group_name = azurerm_resource_group.testing.name

  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "testing" {
  network_interface_id      = azurerm_network_interface.testing.id
  network_security_group_id = azurerm_network_security_group.testing.id
}

