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
}

module "glue_jobs" {
  source = "git::https://github.com/jhonnjc15/artifact3-terraform-templates.git//modules/glue_job?ref=main"

  artifact_bucket = var.artifact_bucket
  temp_bucket     = var.temp_bucket
  glue_role_arn   = var.glue_role_arn
  scripts_prefix  = "glue/jobs/${local.deploy_config.environment}"

  glue_jobs = local.enabled_glue_jobs

  tags = {
    environment = local.deploy_config.environment
    managed_by  = "terraform"
    artifact    = "artefacto3-demo"
  }
}
