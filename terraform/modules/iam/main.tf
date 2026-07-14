# ============================================================
# IAM Module
# Creates IAM Role, Policy Attachments, and Instance Profile
# Follows least privilege principle - no AdministratorAccess
# ============================================================

locals {
  common_tags = {
    Environment = var.environment
    Project     = "notes-crud"
    ManagedBy   = "terraform"
    Owner       = var.owner
  }

  role_name    = "${var.environment}-ec2-instance-role"
  profile_name = "${var.environment}-ec2-instance-profile"
  policy_name  = "${var.environment}-ec2-instance-policy"
}

# -----------------------------------------------------------
# IAM Role for EC2 Instances
# Allows SSM, CloudWatch, EC2 read, and Logs permissions
# -----------------------------------------------------------
resource "aws_iam_role" "ec2_instance" {
  name = local.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = merge(local.common_tags, {
    Name = local.role_name
  })
}

# -----------------------------------------------------------
# Inline Policy for EC2 Instance Role
# Least privilege: CloudWatch Agent, SSM, EC2 Read, Logs
# -----------------------------------------------------------
resource "aws_iam_role_policy" "ec2_instance" {
  name = local.policy_name
  role = aws_iam_role.ec2_instance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:DescribeAssociation",
          "ssm:GetDeployablePatchSnapshotForInstance",
          "ssm:GetDocument",
          "ssm:DescribeDocument",
          "ssm:GetManifest",
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
          "ssm:ListAssociations",
          "ssm:ListInstanceAssociations",
          "ssm:PutInventory",
          "ssm:PutComplianceItems",
          "ssm:PutConfigurePackageResult",
          "ssm:UpdateAssociationStatus",
          "ssm:UpdateInstanceAssociationStatus",
          "ssm:UpdateInstanceInformation"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2messages:AcknowledgeMessage",
          "ec2messages:DeleteMessage",
          "ec2messages:FailMessage",
          "ec2messages:GetEndpoint",
          "ec2messages:GetMessages",
          "ec2messages:SendReply"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups"
        ]
        Resource = [
          "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/ec2/${var.environment}/*",
          "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/ssm/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumesModifications",
          "ec2:DescribeInstanceAttribute",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeNetworkInterfaces"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.cloudwatch_agent_s3_bucket}",
          "arn:aws:s3:::${var.cloudwatch_agent_s3_bucket}/*"
        ]
      }
    ]
  })
}

# -----------------------------------------------------------
# Attach AWS Managed Policy for CloudWatch Agent
# Provides CloudWatchAgentServerPolicy permissions
# -----------------------------------------------------------
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2_instance.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# -----------------------------------------------------------
# Attach AWS Managed Policy for SSM
# Provides AmazonSSMManagedInstanceCore permissions
# -----------------------------------------------------------
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# -----------------------------------------------------------
# IAM Instance Profile
# Attached to EC2 instances via Launch Template
# -----------------------------------------------------------
resource "aws_iam_instance_profile" "ec2_instance" {
  name = local.profile_name
  role = aws_iam_role.ec2_instance.name

  tags = merge(local.common_tags, {
    Name = local.profile_name
  })
}