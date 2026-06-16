output "glue_job_names" {
  value = module.glue_jobs.glue_job_names
}

output "script_s3_locations" {
  value = module.glue_jobs.script_s3_locations
}

output "athena_database_name" {
  value = module.athena.database_name
}

output "athena_workgroup_name" {
  value = module.athena.workgroup_name
}

output "lambda_function_name" {
  value = module.lambda.function_name
}

output "lambda_function_arn" {
  value = module.lambda.function_arn
}
