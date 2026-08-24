# ============================================================================
# Database module (Azure) - PostgreSQL Flexible Server + Key Vault.
#
# Creates: a private PostgreSQL Flexible Server injected into the delegated DB
# subnet (no public network access), a private DNS zone for name resolution,
# and a Key Vault holding the generated credentials + runtime secrets. Nothing
# sensitive is hard-coded; the VMSS reads the secret at boot via its managed
# identity.
# ============================================================================

data "azurerm_client_config" "current" {}

locals {
  name_prefix  = "${var.project_name}-${var.environment}"
  kv_name      = "${lower(replace(var.project_name, "-", ""))}${lower(replace(var.environment, "-", ""))}kv"
  secret_name  = "${local.name_prefix}-db-credentials"
  db_name_dash = "${local.name_prefix}-pg"
}

# ---------------------------------------------------------------------------
# Generated credentials (stored only in Key Vault + Terraform state).
# ---------------------------------------------------------------------------
resource "random_password" "db_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}:?"
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
}

resource "random_password" "jwt_secret" {
  length  = 48
  special = false
}

# ---------------------------------------------------------------------------
# Key Vault (holds DB credentials + app runtime secrets).
# ---------------------------------------------------------------------------
resource "azurerm_key_vault" "this" {
  name                            = local.kv_name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  sku_name                        = "standard"
  purge_protection_enabled        = false
  enabled_for_template_deployment = true

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
    ]
  }

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_key_vault_secret" "db_credentials" {
  name         = local.secret_name
  key_vault_id = azurerm_key_vault.this.id
  value = jsonencode({
    username   = var.db_username
    password   = random_password.db_password.result
    host       = azurerm_postgresql_flexible_server.this.fqdn
    port       = 5432
    dbname     = var.db_name
    jwt_secret = random_password.jwt_secret.result
  })

  depends_on = [azurerm_key_vault.this]
}

# ---------------------------------------------------------------------------
# Private DNS zone for PostgreSQL private endpoints.
# ---------------------------------------------------------------------------
resource "azurerm_private_dns_zone" "postgres" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = var.resource_group_name

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "${local.name_prefix}-pg-link"
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = var.vnet_id
  resource_group_name   = var.resource_group_name
  registration_enabled  = false
}

# ---------------------------------------------------------------------------
# PostgreSQL Flexible Server (private, encrypted, zone-redundant when asked).
# ---------------------------------------------------------------------------
resource "azurerm_postgresql_flexible_server" "this" {
  name                          = local.db_name_dash
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = var.pg_version
  delegated_subnet_id           = var.db_subnet_id
  private_dns_zone_id           = azurerm_private_dns_zone.postgres.id
  public_network_access_enabled = false

  administrator_login    = var.db_username
  administrator_password = random_password.db_password.result

  sku_name   = var.db_sku
  storage_mb = max(var.db_allocated_storage_gb * 1024, 32768)

  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.db_multi_az
  zone                         = "1"

  dynamic "high_availability" {
    for_each = var.db_multi_az ? [1] : []
    content {
      mode                      = "ZoneRedundant"
      standby_availability_zone = "2"
    }
  }

  # Note: flexible server deletion protection is controlled via the Azure
  # portal / CLI; the provider argument is not available in this version.
  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_postgresql_flexible_server_database" "this" {
  name      = var.db_name
  server_id = azurerm_postgresql_flexible_server.this.id
  charset   = "UTF8"
  collation = "C"
}
