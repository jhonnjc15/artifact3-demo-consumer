locals {
  deploy_config = jsondecode(file("${path.module}/deploy.json"))
  environments  = ["dev", "qas", "prd"]

  raw_databases     = try(local.deploy_config.databases, {})
  raw_glue_jobs     = try(local.deploy_config.glue_jobs, {})
  raw_athena_tables = try(local.deploy_config.athena, {})
  raw_lambdas       = try(local.deploy_config.lambda, {})

  enabled_databases = {
    for database_key, database_config in local.raw_databases :
    database_key => merge(
      database_config,
      {
        name = trimspace(database_config.name)
        mode = lower(try(
          trimspace(database_config.environment_values[var.environment].mode),
          trimspace(database_config.mode),
          "existing"
        ))
      }
    )
    if try(database_config.enabled, true) && contains(try(database_config.enabled_environments, local.environments), var.environment)
  }

  enabled_glue_jobs = {
    for job_key, job_config in local.raw_glue_jobs :
    job_key => merge(
      job_config,
      {
        script_local_path = abspath("${path.module}/${job_config.script_local_path}")
        job_name          = trimspace(job_config.job_name)
        default_arguments = merge(
          try(job_config.default_arguments, {}),
          { "--demo_env" = var.environment }
        )
      }
    )
    if try(job_config.enabled, true) && contains(try(job_config.enabled_environments, local.environments), var.environment)
  }

  enabled_athena_tables = {
    for table_key, table_config in local.raw_athena_tables :
    table_key => merge(
      table_config,
      {
        sql_path      = abspath("${path.module}/${table_config.sql_path}")
        database_key  = try(trimspace(table_config.database_key), null)
        database_name = try(trimspace(table_config.database_key), "") != "" ? local.enabled_databases[trimspace(table_config.database_key)].name : (try(trimspace(table_config.database_name), "") != "" ? trimspace(table_config.database_name) : null)
        s3_location   = try(trimspace(table_config.s3_location), "") != "" ? trimspace(table_config.s3_location) : try(table_config.environment_values[var.environment].s3_location, null)
        parameters    = merge(try(table_config.parameters, {}), try(table_config.environment_values[var.environment].parameters, {}))
      }
    )
    if try(table_config.enabled, true) && contains(try(table_config.enabled_environments, local.environments), var.environment)
  }

  enabled_lambdas = {
    for lambda_key, lambda_config in local.raw_lambdas :
    lambda_key => merge(
      lambda_config,
      {
        source_path   = abspath("${path.module}/${lambda_config.source_path}")
        function_name = trimspace(lambda_config.function_name)
      }
    )
    if try(lambda_config.enabled, true) && contains(try(lambda_config.enabled_environments, local.environments), var.environment)
  }

  common_tags = {
    environment = var.environment
    managed_by  = "terraform"
    github_repo = var.github_repository
  }
}

resource "aws_glue_catalog_database" "databases" {
  for_each = {
    for database_key, database_config in local.enabled_databases :
    database_key => database_config
    if database_config.mode == "create"
  }

  name        = each.value.name
  description = try(each.value.description, "Database gestionada por Terraform")

  tags = merge(local.common_tags, try(each.value.tags, {}))
}

module "glue_jobs" {
  source = "../artifact3-terraform-templates/modules/glue_job"

  artifact_bucket = var.artifact_bucket
  temp_bucket     = var.temp_bucket
  glue_role_arn   = var.glue_role_arn
  scripts_prefix  = "glue/jobs/${var.environment}"

  glue_jobs = local.enabled_glue_jobs

  tags = local.common_tags

  depends_on = [module.athena]
}

module "athena" {
  for_each = local.enabled_athena_tables
  source   = "../artifact3-terraform-templates/modules/athena"

  athena = each.value
  tags   = local.common_tags

  depends_on = [aws_glue_catalog_database.databases]
}

module "lambda" {
  for_each = local.enabled_lambdas
  source   = "../artifact3-terraform-templates/modules/lambda"

  artifact_bucket = var.artifact_bucket
  lambda_role_arn = var.lambda_role_arn
  lambda          = each.value
  code_prefix     = "lambda/code/${var.environment}"
  tags            = local.common_tags
}
