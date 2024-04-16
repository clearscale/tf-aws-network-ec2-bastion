resource "aws_network_interface" "this" {
  count             = (var.ec2_ip_private != null ? 1 : 0)
  subnet_id         = var.subnet_ids[0]
  private_ips       = [var.ec2_ip_private]
  security_groups   = [aws_security_group.this.id]
  source_dest_check = true

  tags = {
    Name = local.name
  }
}

resource "aws_instance" "this" {
  ami               = var.ec2_ami
  key_name          = (var.ec2_key_name != null ? var.ec2_key_name : null)
  availability_zone = var.az

  subnet_id = (var.ec2_ip_private != null
    ? null
    : var.subnet_ids[0]
  )

  associate_public_ip_address = (var.ec2_ip_private != null 
    ? null 
    : var.ec2_ip_public_auto
  )

  vpc_security_group_ids = (var.ec2_ip_private != null
    ? null
    : [aws_security_group.this.id]
  )

  source_dest_check = (var.ec2_ip_private != null
    ? null
    : true
  )

  capacity_reservation_specification {
    capacity_reservation_preference = "open"
  }

  credit_specification {
    cpu_credits = "unlimited"
  }

  disable_api_termination = false
  iam_instance_profile    = aws_iam_instance_profile.this.name
  instance_type           = var.ec2_type

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "optional"
    instance_metadata_tags      = "disabled"
  }

  dynamic "root_block_device" {
    for_each = var.ec2_vol_root != null ? [var.ec2_vol_root] : []
    content {
      delete_on_termination = root_block_device.value.delete
      volume_size           = root_block_device.value.size
      volume_type           = root_block_device.value.type

      iops = (root_block_device.value.iops != null 
        ? root_block_device.value.iops
        : null
      )
    }
  }

  dynamic "network_interface" {
    for_each = (var.ec2_ip_private != null ? [var.ec2_ip_private] : [])
    content {
      network_interface_id = aws_network_interface.this[0].id
      device_index         = 0
    }
  }

  user_data = (var.ec2_script != null ? var.ec2_script : null)

  tags = {
    Name = local.name
  }

  lifecycle {
    ignore_changes = [
      user_data,
      disable_api_termination
    ]
  }

  depends_on = [
    aws_security_group.this,
    aws_network_interface.this,
    aws_iam_instance_profile.this,
    aws_iam_role.this,
    aws_iam_role.ssm_fleet_manager
  ]
}

resource "aws_ebs_volume" "this" {
  count = (var.ec2_vol_user != null ? 1 : 0)

  availability_zone = aws_instance.this.availability_zone
  size              = var.ec2_vol_user.size
  type              = var.ec2_vol_user.type
  encrypted         = true

  tags = {
    Name = local.name
  }
}

resource "aws_volume_attachment" "this" {
  count = (var.ec2_vol_user != null ? 1 : 0)

  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.this[0].id
  instance_id = aws_instance.this.id
}

resource "aws_ec2_instance_state" "this" {
  instance_id = aws_instance.this.id
  state       = (var.ec2_start != true ? "stopped" : "running")

  lifecycle {
    ignore_changes = [
      state
    ]
  }
}