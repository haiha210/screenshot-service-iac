# Data sources for reading deployment artifacts from S3
# Lambda-related configuration has been moved to 5.api module

# Data source to read ECS task definition (used by 4.backend module)
data "aws_s3_object" "ecs_task_definition" {
  bucket = module.artifacts_bucket.bucket_id
  key    = "ecs/task-definition.json"

  depends_on = [module.artifacts_bucket]
}

# Output for ECS artifacts
output "ecs_task_definition_version_id" {
  value       = data.aws_s3_object.ecs_task_definition.version_id
  description = "Version ID of the ECS task definition"
}
