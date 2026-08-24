# ============================================================================
# Security module (Azure) - layered Network Security Groups.
#
#   Internet ─▶ public NSG (App Gateway: 80/443) ─▶ app NSG (from App GW only)
#   ─▶ db NSG (PostgreSQL 5432 from app subnet only, no internet).
#
# Each NSG is associated to its tier's subnets here. Stateful by design:
# return traffic for allowed flows is permitted automatically.
# ============================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ---------------------------------------------------------------------------
# Public NSG - protects the Application Gateway subnet.
# App Gateway v2 requires the AzureLoadBalancer health-probe ports open.
# ---------------------------------------------------------------------------
resource "azurerm_network_security_group" "public" {
  name                = "${local.name_prefix}-public-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_network_security_rule" "public_https" {
  name                        = "allow-https-in"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.public.name
}

resource "azurerm_network_security_rule" "public_http" {
  name                        = "allow-http-in"
  priority                    = 1010
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.public.name
}

resource "azurerm_network_security_rule" "public_health_probe" {
  name                        = "allow-appgw-health-probe"
  priority                    = 1020
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "65200-65535"
  source_address_prefix       = "AzureLoadBalancer"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.public.name
}

resource "azurerm_network_security_rule" "public_out_backend" {
  name                        = "allow-to-app-on-80"
  priority                    = 1000
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = join(",", var.app_subnet_cidrs)
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.public.name
}

resource "azurerm_network_security_rule" "public_out_internet" {
  name                        = "allow-internet-out"
  priority                    = 1010
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "Internet"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.public.name
}

# ---------------------------------------------------------------------------
# App NSG - the ONLY inbound path to the VMSS is from the App Gateway subnet.
# ---------------------------------------------------------------------------
resource "azurerm_network_security_group" "app" {
  name                = "${local.name_prefix}-app-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_network_security_rule" "app_from_appgw" {
  name                        = "allow-appgw-80-in"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = join(",", var.public_subnet_cidrs)
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.app.name
}

# No SSH ingress: admin access is via Azure Bastion / run-command (not opened here).
resource "azurerm_network_security_rule" "app_out_db" {
  name                        = "allow-db-5432-out"
  priority                    = 1000
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = tostring(var.db_port)
  source_address_prefix       = "*"
  destination_address_prefix  = join(",", var.db_subnet_cidrs)
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.app.name
}

resource "azurerm_network_security_rule" "app_out_internet" {
  name                        = "allow-internet-out"
  priority                    = 1010
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "Internet"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.app.name
}

# ---------------------------------------------------------------------------
# DB NSG - reachable ONLY from the application subnet, port 5432.
# ---------------------------------------------------------------------------
resource "azurerm_network_security_group" "db" {
  name                = "${local.name_prefix}-db-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_network_security_rule" "db_from_app" {
  name                        = "allow-app-5432-in"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = tostring(var.db_port)
  source_address_prefix       = join(",", var.app_subnet_cidrs)
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.db.name
}

# ---------------------------------------------------------------------------
# Subnet associations (layering applied to the network).
# ---------------------------------------------------------------------------
resource "azurerm_subnet_network_security_group_association" "public" {
  count                     = length(var.public_subnet_ids)
  subnet_id                 = var.public_subnet_ids[count.index]
  network_security_group_id = azurerm_network_security_group.public.id
}

resource "azurerm_subnet_network_security_group_association" "app" {
  count                     = length(var.app_subnet_ids)
  subnet_id                 = var.app_subnet_ids[count.index]
  network_security_group_id = azurerm_network_security_group.app.id
}

resource "azurerm_subnet_network_security_group_association" "db" {
  count                     = length(var.db_subnet_ids)
  subnet_id                 = var.db_subnet_ids[count.index]
  network_security_group_id = azurerm_network_security_group.db.id
}
