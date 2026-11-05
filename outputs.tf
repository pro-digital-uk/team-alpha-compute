# ============================================================================
# Outputs for Team Alpha Compute
# ============================================================================

output "ami_id" {
  description = "ID of the AMI used (from team-alpha-infra)"
  value       = data.aws_ami.web_server.id
}

output "ami_name" {
  description = "Name of the AMI used"
  value       = data.aws_ami.web_server.name
}

output "ami_creation_date" {
  description = "Creation date of the AMI"
  value       = data.aws_ami.web_server.creation_date
}

output "instance_ids" {
  description = "IDs of the launched EC2 instances"
  value       = aws_instance.web_server[*].id
}

output "instance_private_ips" {
  description = "Private IP addresses of instances"
  value       = aws_instance.web_server[*].private_ip
}

output "instance_public_ips" {
  description = "Public IP addresses of instances (if available)"
  value       = aws_instance.web_server[*].public_ip
}

output "elastic_ips" {
  description = "Elastic IP addresses assigned to instances"
  value       = var.allocate_elastic_ips ? aws_eip.web_server[*].public_ip : null
}

output "security_group_id" {
  description = "Security group ID for web servers"
  value       = aws_security_group.web_server.id
}

output "security_group_name" {
  description = "Security group name for web servers"
  value       = aws_security_group.web_server.name
}

output "instance_details" {
  description = "Detailed information about instances"
  value = [
    for i, instance in aws_instance.web_server : {
      instance_id   = instance.id
      instance_type = instance.instance_type
      private_ip    = instance.private_ip
      public_ip     = instance.public_ip
      availability_zone = instance.availability_zone
      elastic_ip    = var.allocate_elastic_ips ? aws_eip.web_server[i].public_ip : null
    }
  ]
}

output "web_server_urls" {
  description = "URLs to access the web servers"
  value = var.allocate_elastic_ips ? [
    for eip in aws_eip.web_server : "http://${eip.public_ip}"
  ] : [
    for instance in aws_instance.web_server : "http://${instance.public_ip}"
  ]
}

output "ssh_commands" {
  description = "SSH commands to connect to instances"
  value = [
    for i, instance in aws_instance.web_server :
    "ssh -i ~/.ssh/your-key.pem ec2-user@${var.allocate_elastic_ips ? aws_eip.web_server[i].public_ip : instance.public_ip}"
  ]
}

output "curl_commands" {
  description = "Curl commands to test the web servers"
  value = [
    for i, instance in aws_instance.web_server :
    "curl http://${var.allocate_elastic_ips ? aws_eip.web_server[i].public_ip : instance.public_ip}"
  ]
}

output "terraform_workspace" {
  description = "Current Terraform workspace"
  value       = terraform.workspace
}

output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    environment     = var.environment
    instance_count  = var.instance_count
    instance_type   = var.instance_type
    ami_id          = data.aws_ami.web_server.id
    ami_name        = data.aws_ami.web_server.name
    security_group  = aws_security_group.web_server.id
    has_elastic_ips = var.allocate_elastic_ips
  }
}
