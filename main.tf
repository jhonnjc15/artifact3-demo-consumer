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

  athena_sql_path = try(local.deploy_config.athena.sql_path, null)
  athena_abs_path = local.athena_sql_path != null ? abspath("${path.module}/${local.athena_sql_path}") : null

  athena_config = merge(
    try(local.deploy_config.athena, {}),
    { sql_path = local.athena_abs_path }
  )

  lambda_source_path = try(local.deploy_config.lambda.source_path, null)
  lambda_abs_path    = local.lambda_source_path != null ? abspath("${path.module}/${local.lambda_source_path}") : null

  lambda_config = merge(
    try(local.deploy_config.lambda, {}),
    { source_path = local.lambda_abs_path }
  )

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
  source = "git::https://github.com/jhonnjc15/artifact3-terraform-templates.git//modules/athena?ref=main"

  athena        = local.athena_config
  output_bucket = var.artifact_bucket
  tags          = local.common_tags
}

module "lambda" {
  source = "git::https://github.com/jhonnjc15/artifact3-terraform-templates.git//modules/lambda?ref=main"

  artifact_bucket = var.artifact_bucket
  lambda_role_arn = var.lambda_role_arn
  lambda          = local.lambda_config
  tags            = local.common_tags
}
