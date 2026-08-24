# ============================================================================
# ALB module (Azure) - Application Gateway + WAF.
#
# Creates: a public IP, a user-assigned identity for the gateway, a Key Vault
# holding a self-signed TLS certificate, an Application Gateway (WAF_v2) with
# an HTTPS listener (HTTP -> HTTPS redirect) and a WAF policy (OWASP 3.2).
# The backend pool is populated from the VMSS network interfaces.
# ============================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# Identity the gateway uses to fetch its TLS certificate from Key Vault.
resource "azurerm_user_assigned_identity" "appgw" {
  name                = "${local.name_prefix}-appgw-identity"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_public_ip" "appgw" {
  name                = "${local.name_prefix}-appgw-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# Key Vault for the gateway's TLS certificate.
# ---------------------------------------------------------------------------
resource "azurerm_key_vault" "appgw" {
  name                     = "${lower(replace(var.project_name, "-", ""))}${lower(replace(var.environment, "-", ""))}appgwkv"
  location                 = var.location
  resource_group_name      = var.resource_group_name
  tenant_id                = var.tenant_id
  sku_name                 = "standard"
  purge_protection_enabled = false

  access_policy {
    tenant_id = var.tenant_id
    object_id = var.deployer_object_id

    certificate_permissions = ["Create", "Get", "List"]
    secret_permissions      = ["Get", "List", "Set", "Delete"]
  }

  # The gateway identity fetches the certificate at runtime.
  access_policy {
    tenant_id = var.tenant_id
    object_id = azurerm_user_assigned_identity.appgw.principal_id

    certificate_permissions = ["Get"]
    secret_permissions      = ["Get"]
  }

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_key_vault_certificate" "appgw" {
  name         = "${local.name_prefix}-tls"
  key_vault_id = azurerm_key_vault.appgw.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = false
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      subject            = "CN=${var.domain_name != "" ? var.domain_name : "localhost"}"
      validity_in_months = 12
      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]
    }
  }
}

# ---------------------------------------------------------------------------
# WAF policy (managed OWASP rules).
# ---------------------------------------------------------------------------
resource "azurerm_web_application_firewall_policy" "this" {
  count               = var.enable_waf ? 1 : 0
  name                = "${local.name_prefix}-waf"
  location            = var.location
  resource_group_name = var.resource_group_name

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    request_body_check          = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }

  tags = {
    Environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# Application Gateway.
# NOTE: the backend pool is intentionally left without static IPs - the VMSS
# joins it via application_gateway_backend_address_pool_ids on its
# ip_configuration (see modules/compute), which stays correct as instances
# scale in/out.
# ---------------------------------------------------------------------------
resource "azurerm_application_gateway" "this" {
  name                = "${local.name_prefix}-appgw"
  location            = var.location
  resource_group_name = var.resource_group_name

  sku {
    name = var.enable_waf ? "WAF_v2" : "Standard_v2"
    tier = var.enable_waf ? "WAF_v2" : "Standard_v2"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.appgw.id]
  }

  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = var.public_subnet_id
  }

  frontend_port {
    name = "port_80"
    port = 80
  }

  frontend_port {
    name = "port_443"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "public"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  backend_address_pool {
    name = "${local.name_prefix}-backend"
  }

  backend_http_settings {
    name                  = "appgw-settings"
    cookie_based_affinity = "Disabled"
    port                  = var.app_port
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "http"
    frontend_ip_configuration_name = "public"
    frontend_port_name             = "port_80"
    protocol                       = "Http"
  }

  http_listener {
    name                           = "https"
    frontend_ip_configuration_name = "public"
    frontend_port_name             = "port_443"
    protocol                       = "Https"
    ssl_certificate_name           = "appgw-ssl"
  }

  ssl_certificate {
    name                = "appgw-ssl"
    key_vault_secret_id = azurerm_key_vault_certificate.appgw.secret_id
  }

  redirect_configuration {
    name                 = "redirect-to-https"
    redirect_type        = "Permanent"
    target_listener_name = "https"
    include_path         = true
    include_query_string = true
  }

  request_routing_rule {
    name                        = "http-redirect"
    rule_type                   = "Basic"
    http_listener_name          = "http"
    redirect_configuration_name = "redirect-to-https"
    priority                    = 100
  }

  request_routing_rule {
    name                       = "https-rule"
    rule_type                  = "Basic"
    http_listener_name         = "https"
    backend_address_pool_name  = "${local.name_prefix}-backend"
    backend_http_settings_name = "appgw-settings"
    priority                   = 200
  }

  firewall_policy_id = var.enable_waf ? azurerm_web_application_firewall_policy.this[0].id : null

  enable_http2 = false
  tags = {
    Environment = var.environment
  }
}
