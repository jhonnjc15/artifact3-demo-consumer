locals {
  deploy_config = jsondecode(file("${path.module}/deploy.json"))

  enabled_glue_jobs = {
    for job_key, job_config in local.deploy_config.glue_jobs :
    job_key => merge(
      job_config,
      {
        script_local_path = abspath("${path.module}/${job_config.script_local_path}")
      }
    )
    if try(job_config.enabled, true)
  }

  enabled_athena_tables = {
    for table_key, table_config in local.deploy_config.athena :
    table_key => merge(
      table_config,
      {
        sql_path = abspath("${path.module}/${table_config.sql_path}")
      }
    )
    if try(table_config.enabled, true)
  }

  enabled_lambdas = {
    for lambda_key, lambda_config in local.deploy_config.lambda :
    lambda_key => merge(
      lambda_config,
      {
        source_path = abspath("${path.module}/${lambda_config.source_path}")
      }
    )
    if try(lambda_config.enabled, true)
  }

  common_tags = {
    environment = local.deploy_config.environment
    managed_by  = "terraform"
    artifact    = "artefacto3-demo"
  }
}

module "glue_jobs" {
  source = "git::https://github.com/jhonnjc15/artifact3-terraform-templates.git//modules/glue_job?ref=main"

  artifact_bucket = var.artifact_bucket
  temp_bucket     = var.temp_bucket
  glue_role_arn   = var.glue_role_arn
  scripts_prefix  = "glue/jobs/${local.deploy_config.environment}"

  glue_jobs = local.enabled_glue_jobs

  tags = local.common_tags
}

module "athena" {
  for_each = local.enabled_athena_tables
  source   = "git::https://github.com/jhonnjc15/artifact3-terraform-templates.git//modules/athena?ref=main"

  athena = each.value
  tags   = local.common_tags
}

module "lambda" {
  for_each = local.enabled_lambdas
  source   = "git::https://github.com/jhonnjc15/artifact3-terraform-templates.git//modules/lambda?ref=main"

  artifact_bucket = var.artifact_bucket
  lambda_role_arn = var.lambda_role_arn
  lambda          = each.value
  code_prefix     = "lambda/code/${local.deploy_config.environment}"
  tags            = local.common_tags
}
