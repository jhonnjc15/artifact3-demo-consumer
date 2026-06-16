output "glue_job_names" {
  value = module.glue_jobs.glue_job_names
}

output "script_s3_locations" {
  value = module.glue_jobs.script_s3_locations
}
