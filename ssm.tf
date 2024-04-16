#
# Systems & Session Manager related resources
#
# This role allows Fleet Manager to manage all EC2 instances. It should
# be specified when enabling "Configure Default Host Management" via the
# Fleet Manager console.
#
resource "aws_iam_role" "ssm_fleet_manager" {
  name                  = "SSMFleetManager"
  description           = "Role to allow SSM Fleet Manager to manage all supported EC2 instances."
  path                  = "/"
  force_detach_policies = false
  max_session_duration  = 3600

  managed_policy_arns = [
      "arn:${local.arn_partition}:iam::aws:policy/AWSApplicationMigrationSSMAccess",
      "arn:${local.arn_partition}:iam::aws:policy/AmazonSSMAutomationApproverAccess",
      "arn:${local.arn_partition}:iam::aws:policy/AmazonSSMManagedEC2InstanceDefaultPolicy",
      "arn:${local.arn_partition}:iam::aws:policy/AmazonSSMManagedInstanceCore",
      "arn:${local.arn_partition}:iam::aws:policy/AmazonSSMPatchAssociation",
      "arn:${local.arn_partition}:iam::aws:policy/AmazonSSMReadOnlyAccess",
      "arn:${local.arn_partition}:iam::aws:policy/service-role/AWSFaultInjectionSimulatorSSMAccess",
      "arn:${local.arn_partition}:iam::aws:policy/service-role/AmazonEC2RoleforSSM",
      "arn:${local.arn_partition}:iam::aws:policy/service-role/AmazonSSMAutomationRole",
      "arn:${local.arn_partition}:iam::aws:policy/service-role/AmazonSSMMaintenanceWindowRole"
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