# ECR Repository for Screenshot Service Backend

resource "aws_ecr_repository" "screenshot_service" {
  name                 = "${var.project}-${var.env}-screenshot-service"
  image_tag_mutability = "IMMUTABLE" # Prevent tag overwriting for security and compliance

  # Enable image scanning on push for security
  image_scanning_configuration {
    scan_on_push = true
  }

  # Enable encryption at rest with Customer Managed Key (CMK)
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = data.terraform_remote_state.general.outputs.ecr_kms_key_arn
  }

  tags = {
    Name        = "${var.project}-${var.env}-screenshot-service"
    Environment = var.env
    Project     = var.project
    Purpose     = "Docker images for ECS backend service"
  }
}

# Lifecycle policy to keep only recent images
resource "aws_ecr_lifecycle_policy" "screenshot_service" {
  repository = aws_ecr_repository.screenshot_service.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ECR Repository Policy - Allow pull from ECS execution role
resource "aws_ecr_repository_policy" "screenshot_service" {
  repository = aws_ecr_repository.screenshot_service.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowECSTaskExecutionRolePull"
        Effect = "Allow"
        Principal = {
          AWS = data.terraform_remote_state.general.outputs.ecs_task_execution_role_arn
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      },
      # {
      #   Sid    = "AllowCICDPush"
      #   Effect = "Allow"
      #   Principal = {
      #     AWS = aws_iam_role.cicd_role.arn
      #   }
      #   Action = [
      #     "ecr:GetDownloadUrlForLayer",
      #     "ecr:BatchGetImage",
      #     "ecr:BatchCheckLayerAvailability",
      #     "ecr:PutImage",
      #     "ecr:InitiateLayerUpload",
      #     "ecr:UploadLayerPart",
      #     "ecr:CompleteLayerUpload"
      #   ]
      # }
    ]
  })
}

# Outputs
output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.screenshot_service.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.screenshot_service.arn
}

output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.screenshot_service.name
}
