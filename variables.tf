variable "aws_region" {
  description = "Región AWS donde se desplegará el Glue Job."
  type        = string
  default     = "us-east-1"
}

variable "artifact_bucket" {
  description = "Bucket S3 donde se subirá el script Python del Glue Job."
  type        = string
}

variable "temp_bucket" {
  description = "Bucket S3 usado por Glue como TempDir."
  type        = string
}

variable "glue_role_arn" {
  description = "ARN del IAM Role existente que usará AWS Glue."
  type        = string
}

variable "lambda_role_arn" {
  description = "ARN del IAM Role existente que usará AWS Lambda."
  type        = string
}
