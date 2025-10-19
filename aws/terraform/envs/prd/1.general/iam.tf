# IAM Policy Documents
data "aws_iam_policy_document" "assume_role_lambda" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# IAM Role for VPC Flow Logs
resource "aws_iam_role" "vpc_flow_logs" {
  name = "${var.project}-${var.env}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project}-${var.env}-vpc-flow-logs-role"
    Environment = var.env
    Project     = var.project
  }
}

# IAM Policy for VPC Flow Logs to write to CloudWatch
resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "${var.project}-${var.env}-vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "${aws_cloudwatch_log_group.vpc_flow_logs.arn}:*"
      }
    ]
  })
}

# IAM Role for Lambda Functions
resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.project}-${var.env}-lambda-execution-role"

  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json

  tags = {
    Name        = "${var.project}-${var.env}-lambda-execution-role"
    Environment = var.env
    Project     = var.project
  }
}

# IAM Role for ECS Tasks
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project}-${var.env}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project}-${var.env}-ecs-task-role"
    Environment = var.env
    Project     = var.project
  }
}

# IAM Role for ECS Task Execution (for pulling images, logging)
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project}-${var.env}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project}-${var.env}-ecs-task-execution-role"
    Environment = var.env
    Project     = var.project
  }
}

# IAM Policy Document for DynamoDB Access
data "aws_iam_policy_document" "dynamodb_access" {
  statement {
    sid    = "AllowDynamoDBAccess"
    effect = "Allow"

    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan"
    ]

    resources = [
      "arn:aws:dynamodb:${var.region}:*:table/screenshot-results-${var.env}",
      "arn:aws:dynamodb:${var.region}:*:table/screenshot-results-${var.env}/index/*"
    ]
  }
}

# IAM Policy for DynamoDB Access
resource "aws_iam_policy" "dynamodb_access" {
  name        = "${var.project}-${var.env}-dynamodb-access"
  description = "IAM policy for DynamoDB access to screenshot results table"
  policy      = data.aws_iam_policy_document.dynamodb_access.json

  tags = {
    Name        = "${var.project}-${var.env}-dynamodb-access"
    Environment = var.env
    Project     = var.project
  }
}

# IAM Policy Document for Screenshots S3 Bucket Access
data "aws_iam_policy_document" "screenshots_s3_access" {
  statement {
    sid    = "AllowScreenshotsS3Access"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]

    resources = [
      module.screenshots_bucket.bucket_arn,
      "${module.screenshots_bucket.bucket_arn}/*"
    ]
  }
}

# IAM Policy Document for Artifacts S3 Bucket Access (Read-only for Lambda/ECS)
data "aws_iam_policy_document" "artifacts_s3_access" {
  statement {
    sid    = "AllowArtifactsS3Access"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:GetBucketVersioning"
    ]

    resources = [
      module.artifacts_bucket.bucket_arn,
      "${module.artifacts_bucket.bucket_arn}/*"
    ]
  }
}

# IAM Policy for Screenshots S3 Bucket Access
resource "aws_iam_policy" "screenshots_s3_access" {
  name        = "${var.project}-${var.env}-screenshots-s3-access"
  description = "IAM policy for screenshots S3 bucket access"
  policy      = data.aws_iam_policy_document.screenshots_s3_access.json

  tags = {
    Name        = "${var.project}-${var.env}-screenshots-s3-access"
    Environment = var.env
    Project     = var.project
    Purpose     = "Access to screenshots storage bucket"
  }
}

# IAM Policy for Artifacts S3 Bucket Access (Read-only)
resource "aws_iam_policy" "artifacts_s3_access" {
  name        = "${var.project}-${var.env}-artifacts-s3-access"
  description = "IAM policy for artifacts S3 bucket read access"
  policy      = data.aws_iam_policy_document.artifacts_s3_access.json

  tags = {
    Name        = "${var.project}-${var.env}-artifacts-s3-access"
    Environment = var.env
    Project     = var.project
    Purpose     = "Read access to deployment artifacts bucket"
  }
}

# IAM Policy Document for Lambda SQS Access (Send only)
data "aws_iam_policy_document" "lambda_sqs_access" {
  statement {
    sid    = "AllowLambdaSQSAccess"
    effect = "Allow"

    actions = [
      "sqs:SendMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl"
    ]

    resources = concat([
      aws_sqs_queue.screenshot_queue.arn,
      aws_sqs_queue.screenshot_priority_queue.arn
      ], var.env == "prd" ? [
      aws_sqs_queue.screenshot_fifo_queue[0].arn
    ] : [])
  }
}

# IAM Policy Document for ECS SQS Access (Receive and Delete)
data "aws_iam_policy_document" "ecs_sqs_access" {
  statement {
    sid    = "AllowECSSQSAccess"
    effect = "Allow"

    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ChangeMessageVisibility"
    ]

    resources = concat([
      aws_sqs_queue.screenshot_queue.arn,
      aws_sqs_queue.screenshot_priority_queue.arn,
      aws_sqs_queue.screenshot_dlq.arn
      ], var.env == "prd" ? [
      aws_sqs_queue.screenshot_fifo_queue[0].arn,
      aws_sqs_queue.screenshot_fifo_dlq[0].arn
    ] : [])
  }
}

# IAM Policy for Lambda SQS Access (Send messages)
resource "aws_iam_policy" "lambda_sqs_access" {
  name        = "${var.project}-${var.env}-lambda-sqs-access"
  description = "IAM policy for Lambda to send messages to SQS queues"
  policy      = data.aws_iam_policy_document.lambda_sqs_access.json

  tags = {
    Name        = "${var.project}-${var.env}-lambda-sqs-access"
    Environment = var.env
    Project     = var.project
  }
}

# IAM Policy for ECS SQS Access (Receive and process messages)
resource "aws_iam_policy" "ecs_sqs_access" {
  name        = "${var.project}-${var.env}-ecs-sqs-access"
  description = "IAM policy for ECS tasks to receive and process SQS messages"
  policy      = data.aws_iam_policy_document.ecs_sqs_access.json

  tags = {
    Name        = "${var.project}-${var.env}-ecs-sqs-access"
    Environment = var.env
    Project     = var.project
  }
}

# Attach AWS managed policy for Lambda basic execution to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach DynamoDB access policy to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_dynamodb_access" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.dynamodb_access.arn
}

# Attach Screenshots S3 access policy to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_screenshots_s3_access" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.screenshots_s3_access.arn
}

# Attach Artifacts S3 read access policy to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_artifacts_s3_access" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.artifacts_s3_access.arn
}

# Attach SQS access policy to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_sqs_access" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_sqs_access.arn
}

# Attach AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Attach DynamoDB access policy to ECS task role
resource "aws_iam_role_policy_attachment" "ecs_dynamodb_access" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.dynamodb_access.arn
}

# Attach Screenshots S3 access policy to ECS task role
resource "aws_iam_role_policy_attachment" "ecs_screenshots_s3_access" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.screenshots_s3_access.arn
}

# Attach Artifacts S3 read access policy to ECS task role (if needed)
resource "aws_iam_role_policy_attachment" "ecs_artifacts_s3_access" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.artifacts_s3_access.arn
}

# Attach SQS access policy to ECS task role
resource "aws_iam_role_policy_attachment" "ecs_sqs_access" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_sqs_access.arn
}

# Outputs
output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_execution_role.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task_role.arn
}

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "dynamodb_access_policy_arn" {
  description = "ARN of the DynamoDB access policy"
  value       = aws_iam_policy.dynamodb_access.arn
}

output "screenshots_s3_access_policy_arn" {
  description = "ARN of the Screenshots S3 access policy"
  value       = aws_iam_policy.screenshots_s3_access.arn
}

output "artifacts_s3_access_policy_arn" {
  description = "ARN of the Artifacts S3 access policy"
  value       = aws_iam_policy.artifacts_s3_access.arn
}

output "lambda_sqs_access_policy_arn" {
  description = "ARN of the Lambda SQS access policy"
  value       = aws_iam_policy.lambda_sqs_access.arn
}

output "ecs_sqs_access_policy_arn" {
  description = "ARN of the ECS SQS access policy"
  value       = aws_iam_policy.ecs_sqs_access.arn
}
