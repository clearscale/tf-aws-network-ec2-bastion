output "ec2_id" {
  description = "The ID of the EC2 Instance that is created."
  value       = aws_instance.this.id
}
