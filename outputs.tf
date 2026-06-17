output "glue_job_names" {
  value = module.glue_jobs.glue_job_names
}

output "script_s3_locations" {
  value = module.glue_jobs.script_s3_locations
}

output "athena_database_names" {
  value = {
    for k, m in module.athena : k => m.database_name
  }
}

output "athena_table_names" {
  value = {
    for k, m in module.athena : k => m.table_name
  }
}

output "athena_s3_locations" {
  value = {
    for k, m in module.athena : k => m.s3_location
  }
}

output "lambda_function_names" {
  value = {
    for k, m in module.lambda : k => m.function_name
  }
}

output "lambda_function_arns" {
  value = {
    for k, m in module.lambda : k => m.function_arn
  }
}
