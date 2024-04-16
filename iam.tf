resource "aws_iam_role" "this" {
  name                  = "${local.name_iam}EC2Host"
  description           = "Role for ${local.name} Bastion EC2 hosts"
  path                  = "/"
  force_detach_policies = false
  max_session_duration  = 3600

  managed_policy_arns = [
    "arn:${local.arn_partition}:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:${local.arn_partition}:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Effect = "Allow"
      },
    ]
  })
}

resource "aws_iam_role_policy" "this" {
  name = "${local.name_iam}EC2HostPolicy"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = "secretsmanager:GetSecretValue",
        Resource = "arn:${local.arn_partition}:secretsmanager:${local.region}:${local.account}:secret:${var.ec2_key}-*",
        Effect   = "Allow",
      },
      {
        Sid    = "EC2BastionGrantECRReadOnlyAccess",
        Effect = "Allow",
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage"
        ],
        Resource = "*"
      },
      {
        Sid      = "EC2BastionGrantECRAuthAccess",
        Effect   = "Allow",
        Action   = "ecr:GetAuthorizationToken",
        Resource = "*"
      },
      {
        Sid      = "EC2BastionGrantEC2Control",
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:StartInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "this" {
  name = "${local.name_iam}EC2Host"
  role = aws_iam_role.this.name
}