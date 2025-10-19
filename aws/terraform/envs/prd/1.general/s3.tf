# S3 Buckets using reusable module

# Screenshots S3 Bucket
module "screenshots_bucket" {
  source = "../../../../modules/s3"

  bucket_name        = "screenshot-bucket"
  env                = var.env
  project            = var.project
  purpose            = "Store screenshot images from backend service"
  versioning_enabled = var.env == "prd"

  lifecycle_rules = [{
    id     = "screenshot_lifecycle"
    status = "Enabled"

    transitions = [
      {
        days          = 30
        storage_class = "STANDARD_IA"
      },
      {
        days          = 90
        storage_class = "GLACIER"
      }
    ]

    noncurrent_expiration_days = 365
    incomplete_multipart_days  = 7
  }]

  cors_configuration = {
    enabled         = true
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = var.env == "prd" ? ["https://yourdomain.com"] : ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# Artifacts S3 Bucket
module "artifacts_bucket" {
  source = "../../../../modules/s3"

  bucket_name        = "screenshot-artifacts"
  env                = var.env
  project            = var.project
  purpose            = "Store deployment artifacts: Lambda code, Swagger files, etc."
  versioning_enabled = true # Always enable versioning for artifacts

  lifecycle_rules = [{
    id     = "artifacts_lifecycle"
    status = "Enabled"

    # Keep non-current versions for rollback capability
    noncurrent_transitions = [
      {
        days          = 30
        storage_class = "STANDARD_IA"
      },
      {
        days          = 90
        storage_class = "GLACIER"
      }
    ]

    # Delete very old versions after 1 year
    noncurrent_expiration_days = 365
    incomplete_multipart_days  = 1
  }]
}

# Access Logs S3 Bucket (Production only)
module "access_logs_bucket" {
  count  = var.env == "prd" ? 1 : 0
  source = "../../../../modules/s3"

  bucket_name        = "screenshot-access-logs"
  env                = var.env
  project            = var.project
  purpose            = "Store S3 access logs for screenshot bucket"
  versioning_enabled = false

  lifecycle_rules = [{
    id              = "access_logs_lifecycle"
    status          = "Enabled"
    expiration_days = 90
  }]
}

# Configure access logging for screenshots bucket
resource "aws_s3_bucket_logging" "screenshots" {
  count = var.env == "prd" ? 1 : 0

  bucket = module.screenshots_bucket.bucket_id

  target_bucket = module.access_logs_bucket[0].bucket_id
  target_prefix = "screenshots-access-logs/"
}

# IAM Policy for CI/CD to upload artifacts
resource "aws_iam_policy" "cicd_artifacts_upload" {
  name        = "${var.project}-${var.env}-cicd-artifacts-upload"
  description = "Allow CI/CD pipeline to upload artifacts to S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowArtifactsUpload"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:GetBucketVersioning"
        ]
        Resource = [
          module.artifacts_bucket.bucket_arn,
          "${module.artifacts_bucket.bucket_arn}/*"
        ]
      }
    ]
  })

  tags = {
    Name        = "${var.project}-${var.env}-cicd-artifacts-upload"
    Environment = var.env
    Project     = var.project
    Purpose     = "Allow CI/CD to upload Lambda code and Swagger files"
  }
}

# IAM Role for CI/CD (GitHub Actions, etc.)
resource "aws_iam_role" "cicd_role" {
  name = "${var.project}-${var.env}-cicd-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          # For GitHub Actions OIDC
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.project}/*"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project}-${var.env}-cicd-role"
    Environment = var.env
    Project     = var.project
    Purpose     = "Role for CI/CD pipeline to deploy artifacts"
  }
}

# Attach artifacts upload policy to CI/CD role
resource "aws_iam_role_policy_attachment" "cicd_artifacts_upload" {
  role       = aws_iam_role.cicd_role.name
  policy_arn = aws_iam_policy.cicd_artifacts_upload.arn
}

# IAM Policy for CI/CD to push Docker images to ECR
resource "aws_iam_policy" "cicd_ecr_push" {
  name        = "${var.project}-${var.env}-cicd-ecr-push"
  description = "Allow CI/CD pipeline to push Docker images to ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowECRPush"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.project}-${var.env}-cicd-ecr-push"
    Environment = var.env
    Project     = var.project
    Purpose     = "Allow CI/CD to push Docker images to ECR"
  }
}

# Attach ECR push policy to CI/CD role
resource "aws_iam_role_policy_attachment" "cicd_ecr_push" {
  role       = aws_iam_role.cicd_role.name
  policy_arn = aws_iam_policy.cicd_ecr_push.arn
}
