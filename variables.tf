locals {
  name          = module.std.names.aws[var.account.name].general
  name_iam      = module.std.names.aws[var.account.name].title
  account       = data.aws_caller_identity.this.account_id
  region        = module.std.region
  arn_partition = (var.arn_partition == null ? data.aws_partition.this.partition : var.arn_partition)
}

variable "prefix" {
  type        = string
  description = "(Optional). Prefix override for all generated naming conventions."
  default     = "cs"
}

variable "client" {
  type        = string
  description = "(Optional). Name of the client"
  default     = "ClearScale"
}

variable "project" {
  type        = string
  description = "(Optional). Name of the client project."
  default     = "pmod"
}

variable "account" {
  description = "(Optional). Current cloud provider account info."
  type = object({
    key      = optional(string, "current")
    provider = optional(string, "aws")
    id       = optional(string, "*") 
    name     = string
    region   = optional(string, null)
  })
  default = {
    id   = "*"
    name = "shared"
  }
}

variable "env" {
  type        = string
  description = "(Optional). Name of the current environment."
  default     = "dev"
}

variable "region" {
  type        = string
  description = "(Optional). Name of the region."
  default     = "us-west-1"
}

variable "name" {
  type        = string
  description = "(Optional). The name of the resource, application, or service."
  default     = "bastion"
}

variable "arn_partition" {
  type        = string
  description = "(Optional). Override the partition to specify in the ARN (aws or aws-us-gov)."
  default     = null
}

variable "az" {
  type        = string
  description = "(Required). Availability zone."
}

variable "vpc_id" {
  type        = string
  description = "(Required). The VPC id for which the EC2 instance should be associated with."
}

variable "subnet_ids" {
  type        = list(string)
  description = "(Required). The VPC Subnet ids for which the EC2 instance should be associated with."
}

#
# https://docs.aws.amazon.com/systems-manager/latest/userguide/ami-preinstalled-agent.html
# Default: Microsoft Windows Server 2022 Base
#
variable "ec2_ami" {
  type        = string
  description = "(Optional). Amazon image ID for the EC2 instance. The images needs to have the SSM agent pre-installed."
  default     = "ami-0aec1cbfa00609468"
}

variable "ec2_start" {
  type        = bool
  description = "(Optional). Start the EC2 instance upon deployment?"
  default     = true
}

variable "ec2_key" {
  type        = string
  description = "(Optional). Secrets manager variable name of where the SSH key is stored. If not set, pass the SSH key name to var.ec2_key_name."
  default     = ""
}

variable "ec2_key_name" {
  type        = string
  description = "(Required). SSH key pair for accessing the EC2 instance."
}

variable "ec2_type" {
  type        = string
  description = "(Optional). EC2 instance type."
  default     = "t3.nano"
}

variable "ec2_ingress" {
  description = "(Optional). Security groups ingress rules."
  type = list(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = list(string)
    security_groups = list(string)
  }))
  default = null
}

variable "ec2_vol_root" {
  description = "(Optional). Root volume configuration"
  type = object({
    delete = bool
    size   = number
    type   = string
    iops   = number
  })

  # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-volume-types.html
  default = {
    delete = true # Delete on termination?
    size   = 50
    type   = "gp3"
    iops   = null
  }
}

variable "ec2_vol_user" {
  description = "(Optional). User defined EBS volume configuration"
  type = object({
    size   = number
    type   = string
  })

  # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-volume-types.html
  default = null
}

variable "ec2_ip_private" {
  type        = string
  description = "(Optional). Static private IP address."
  default     = null
}

variable "ec2_ip_public_auto" {
  type        = bool
  description = "(Optional). Auto-assign a public IP address? Cannot be true if var.ec2_ip_private is set."
  default     = false
}

variable "ec2_script" {
  type        = string
  description = "(Optional). User data script to execute when creating the instance."
  default     = null
}