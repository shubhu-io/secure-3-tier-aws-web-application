# ============================================================================
# Compute module (Azure) - VM Scale Set + autoscale.
#
# Creates: a user-assigned managed identity (used by the instances to pull
# images from ACR and read DB credentials from Key Vault - no keys on disk),
# a Linux VMSS running docker-compose, RBAC role assignments (AcrPull on ACR,
# Key Vault Secrets User on the vault), and an autoscale setting driven by
# CPU. Custom data (cloud-init) pulls the images at boot.
# ============================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  vmss_name   = "${local.name_prefix}-vmss"
  admin_user  = "azureuser"
  image_params = {
    for s in var.services : s.name => "${var.acr_login_server}/${s.name}:latest"
  }
}

# ---------------------------------------------------------------------------
# Managed identity for the instances.
# ---------------------------------------------------------------------------
resource "azurerm_user_assigned_identity" "vmss" {
  name                = "${local.name_prefix}-vmss-identity"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = {
    Environment = var.environment
  }
}

# Least-privilege: pull images from ACR, read the DB secret from Key Vault.
resource "azurerm_role_assignment" "acr_pull" {
  principal_id         = azurerm_user_assigned_identity.vmss.principal_id
  role_definition_name = "AcrPull"
  scope                = var.acr_id
}

resource "azurerm_role_assignment" "kv_secrets" {
  principal_id         = azurerm_user_assigned_identity.vmss.principal_id
  role_definition_name = "Key Vault Secrets User"
  scope                = var.key_vault_id
}

# ---------------------------------------------------------------------------
# Admin password (random, never reused, not shared). Disable password auth in
# production and use Azure AD / SSH keys instead - see README.
# ---------------------------------------------------------------------------
resource "random_password" "admin" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}:?"
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
}

# ---------------------------------------------------------------------------
# Virtual Machine Scale Set.
# ---------------------------------------------------------------------------
resource "azurerm_linux_virtual_machine_scale_set" "this" {
  name                = local.vmss_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.vm_size
  instances           = var.desired_capacity
  zones               = slice(var.zones, 0, min(length(var.zones), 3))
  upgrade_mode        = "Automatic"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.vmss.id]
  }

  admin_username                  = local.admin_user
  admin_password                  = random_password.admin.result
  disable_password_authentication = false

  custom_data = base64encode(templatefile("${path.module}/user-data.sh", {
    project_name       = var.project_name
    environment        = var.environment
    acr_login_server   = var.acr_login_server
    identity_client_id = azurerm_user_assigned_identity.vmss.client_id
    key_vault_name     = var.key_vault_name
    db_secret_name     = var.db_secret_name
    services_json      = jsonencode(var.services)
  }))

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

  network_interface {
    name    = "${local.name_prefix}-vmss-nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = var.app_subnet_ids[0]

      # Join the Application Gateway backend pool (membership survives
      # scale-in/out, unlike static IP registration).
      application_gateway_backend_address_pool_ids = var.appgw_backend_pool_ids
    }
  }

  tags = {
    Environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# Autoscale - capacity profile + CPU-based scale rules.
# ---------------------------------------------------------------------------
resource "azurerm_monitor_autoscale_setting" "this" {
  name                = "${local.name_prefix}-autoscale"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.this.id

  profile {
    name = "default"

    capacity {
      default = var.desired_capacity
      minimum = var.min_size
      maximum = var.max_size
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.this.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = 1
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.this.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 30
      }
      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = 1
        cooldown  = "PT5M"
      }
    }
  }

  tags = {
    Environment = var.environment
  }
}
