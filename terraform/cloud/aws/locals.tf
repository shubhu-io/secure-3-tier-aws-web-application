# ============================================================================
# Root locals - derived values shared across the modules.
# ============================================================================

locals {
  # Default to the first two AZs if the caller did not pin them
  azs = var.azs != null ? var.azs : [
    data.aws_availability_zones.available.names[0],
    data.aws_availability_zones.available.names[1],
  ]

  # The tech stack lives in stack.json (single source of truth): which
  # services to run, the database engine/version/port and the runtimes.
  # path.root is the terraform/ directory when invoked as a child module, so
  # ../stack.json resolves to the repo root (matches the Azure layout). When
  # the module is validated/planned standalone from its own directory (depth
  # varies), we also try the deeper relative paths.
  stack_file = try(
    file("${path.root}/../stack.json"),
    file("${path.root}/../../stack.json"),
    file("${path.root}/../../../stack.json"),
    file("${path.root}/../../../../stack.json"),
    file("${path.root}/stack.json"),
  )
  stack = jsondecode(local.stack_file)

  services = local.stack.services
  db_port  = local.stack.database.engine == "postgres" ? 5432 : 3306
}