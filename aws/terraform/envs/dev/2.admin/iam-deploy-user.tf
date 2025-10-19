# IAM User for CI/CD Deployment

resource "aws_iam_user" "deploy" {
  name = "${var.project}-${var.env}-deploy"
  path = "/system/"

  tags = {
    Name        = "${var.project}-${var.env}-deploy"
    Environment = var.env
    Project     = var.project
    Purpose     = "CI/CD Deployment"
  }
}

# Access Key for Deployment User
resource "aws_iam_access_key" "deploy" {
  user = aws_iam_user.deploy.name
}

# Deployment Policy
resource "aws_iam_policy" "deploy" {
  name        = "${var.project}-${var.env}-deploy-policy"
  description = "Policy for CI/CD deployment user"

  policy = templatefile("${path.module}/../../../../templates/deploy-user-policy.json", {
    account_id = local.aws_account_id
    region     = local.aws_region
    project    = var.project
    env        = var.env
  })

  tags = {
    Name        = "${var.project}-${var.env}-deploy-policy"
    Environment = var.env
    Project     = var.project
  }
}

# IAM Group for Deployment Users
resource "aws_iam_group" "deploy" {
  name = "${var.project}-${var.env}-deploy-group"
  path = "/system/"
}

# Attach Policy to Group (not directly to user)
resource "aws_iam_group_policy_attachment" "deploy" {
  group      = aws_iam_group.deploy.name
  policy_arn = aws_iam_policy.deploy.arn
}

# Add User to Group
resource "aws_iam_user_group_membership" "deploy" {
  user = aws_iam_user.deploy.name
  groups = [
    aws_iam_group.deploy.name
  ]
}
