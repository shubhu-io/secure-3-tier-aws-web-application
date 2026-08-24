# ============================================================================
# Jenkins module (optional) - self-hosted CI/CD controller on a VM.
#
# Creates a single Linux VM in the public subnet running the Jenkins
# controller in Docker, with az CLI + kubectl preinstalled. The VM uses a
# user-assigned managed identity granted Contributor on the resource group, so
# the Jenkins pipelines deploy via `az` without long-lived credentials.
# ============================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# Identity the Jenkins controller uses to deploy via Azure CLI.
resource "azurerm_user_assigned_identity" "jenkins" {
  name                = "${local.name_prefix}-jenkins-identity"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_role_assignment" "jenkins" {
  principal_id         = azurerm_user_assigned_identity.jenkins.principal_id
  role_definition_name = "Contributor"
  scope                = var.cicd_rg_scope
}

resource "random_password" "admin" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}:?"
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
}

# ---------------------------------------------------------------------------
# NSG for the Jenkins UI + agent port.
# ---------------------------------------------------------------------------
resource "azurerm_network_security_group" "jenkins" {
  name                = "${local.name_prefix}-jenkins-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_network_security_rule" "jenkins_ui" {
  name                        = "allow-jenkins-ui"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "8080"
  source_address_prefixes     = var.ingress_cidrs
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.jenkins.name
}

resource "azurerm_network_security_rule" "jenkins_agent" {
  name                        = "allow-jenkins-agent"
  priority                    = 1010
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "50000"
  source_address_prefixes     = var.ingress_cidrs
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.jenkins.name
}

resource "azurerm_public_ip" "jenkins" {
  name                = "${local.name_prefix}-jenkins-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_network_interface" "jenkins" {
  name                = "${local.name_prefix}-jenkins-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    primary                       = true
    subnet_id                     = var.public_subnet_id
    public_ip_address_id          = azurerm_public_ip.jenkins.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_network_interface_security_group_association" "jenkins" {
  network_interface_id      = azurerm_network_interface.jenkins.id
  network_security_group_id = azurerm_network_security_group.jenkins.id
}

resource "azurerm_linux_virtual_machine" "jenkins" {
  name                            = "${local.name_prefix}-jenkins"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = random_password.admin.result
  disable_password_authentication = false

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.jenkins.id]
  }

  custom_data = base64encode(templatefile("${path.module}/user-data.sh", {
    project_name   = var.project_name
    environment    = var.environment
    admin_username = var.admin_username
  }))

  network_interface_ids = [
    azurerm_network_interface.jenkins.id,
  ]

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  tags = {
    Environment = var.environment
  }
}
