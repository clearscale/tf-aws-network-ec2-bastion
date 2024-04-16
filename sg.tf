resource "aws_security_group" "this" {
  name        = local.name
  description = "Security group for ${var.prefix} ${replace(title(var.name),"-","")} EC2 hosts"
  vpc_id      = var.vpc_id

  # Egress rule, allow all outbound traffic
  egress {
    description = "Allow all outbound traffic."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ingress rule
  dynamic "ingress" {
    for_each = var.ec2_ingress != null ? var.ec2_ingress : []
    content {
      description     = ingress.value.description
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      cidr_blocks     = ingress.value.cidr_blocks
      security_groups = ((length(ingress.value.security_groups) > 0)
        ? ingress.value.security_groups
        : null
      )
    }
  }

  tags = {
    Name = local.name
  }
}