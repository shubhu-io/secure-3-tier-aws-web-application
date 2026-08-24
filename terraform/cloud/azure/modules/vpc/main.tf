# ============================================================================
# VPC module (Azure VNet) - network foundation.
#
# Creates: Virtual Network, public/app/db subnets, NAT Gateway(s),
#          route tables (app -> NAT egress, db -> isolated). NSGs live in the
#          security module but are associated to these subnets there.
# The DB subnet is delegated to Microsoft.DBforPostgreSQL/flexibleServers so
# the PostgreSQL Flexible Server can be injected into it privately.
#
# Outbound internet from the app tier uses the NAT Gateway association on the
# app subnet (no custom 0.0.0.0/0 route needed). The DB subnet has no route
# to the internet at all - it is fully private.
# ============================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "azurerm_virtual_network" "this" {
  name                = "${local.name_prefix}-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.vnet_cidr]

  tags = {
    Environment = var.environment
  }
}

# --- Public subnets (Application Gateway + NAT egress) ----------------------
resource "azurerm_subnet" "public" {
  count                = length(var.public_subnet_cidrs)
  name                 = "${local.name_prefix}-public-${count.index}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [element(var.public_subnet_cidrs, count.index)]
}

# --- Application subnets (VMSS, private, egress via NAT) --------------------
resource "azurerm_subnet" "app" {
  count                = length(var.app_subnet_cidrs)
  name                 = "${local.name_prefix}-app-${count.index}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [element(var.app_subnet_cidrs, count.index)]
}

# --- Database subnets (PostgreSQL, delegated, no internet route) ------------
resource "azurerm_subnet" "db" {
  count                = length(var.db_subnet_cidrs)
  name                 = "${local.name_prefix}-db-${count.index}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [element(var.db_subnet_cidrs, count.index)]
  service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "postgres-delegation"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# ---------------------------------------------------------------------------
# NAT Gateway(s) - one per AZ when nat_gateway_count=2, one shared when =1
# ---------------------------------------------------------------------------
resource "azurerm_public_ip" "nat" {
  count               = var.nat_gateway_count
  name                = "${local.name_prefix}-nat-pip-${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_nat_gateway" "this" {
  count                   = var.nat_gateway_count
  name                    = "${local.name_prefix}-nat-${count.index + 1}"
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  count                = var.nat_gateway_count
  nat_gateway_id       = azurerm_nat_gateway.this[count.index].id
  public_ip_address_id = azurerm_public_ip.nat[count.index].id
}

# App subnets egress through the NAT gateways (provides private outbound to
# ACR / OS updates without exposing the instances).
resource "azurerm_subnet_nat_gateway_association" "app" {
  count          = length(azurerm_subnet.app)
  subnet_id      = azurerm_subnet.app[count.index].id
  nat_gateway_id = azurerm_nat_gateway.this[count.index % var.nat_gateway_count].id
}

# ---------------------------------------------------------------------------
# Route tables.
#   App: custom routes only for on-prem/VNet; default internet egress is via
#        the NAT gateway association above (no 0.0.0.0/0 custom route).
#   DB:  no internet route at all (fully private).
#   Public: none (App Gateway has its own public IP).
# ---------------------------------------------------------------------------
resource "azurerm_route_table" "app" {
  count               = var.nat_gateway_count
  name                = "${local.name_prefix}-app-rt-${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_subnet_route_table_association" "app" {
  count          = length(azurerm_subnet.app)
  subnet_id      = azurerm_subnet.app[count.index].id
  route_table_id = azurerm_route_table.app[count.index % var.nat_gateway_count].id
}

resource "azurerm_route_table" "db" {
  name                = "${local.name_prefix}-db-rt"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_subnet_route_table_association" "db" {
  count          = length(azurerm_subnet.db)
  subnet_id      = azurerm_subnet.db[count.index].id
  route_table_id = azurerm_route_table.db.id
}
