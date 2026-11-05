# ============================================================================
# TEAM ALPHA COMPUTE - EC2 Instance Deployment
# ============================================================================
# This Terraform configuration launches EC2 instances using the AMI built
# by team-alpha-infra repository.
#
# Key Features:
# - Automatically discovers latest AMI by name
# - Launches instances in VPC with security groups
# - Configures Nginx to serve your website
# - Assigns elastic IPs for static addressing
# - Outputs instance details for quick access
# ============================================================================

# Data source: Get the latest web server AMI built by team-alpha-infra
# This looks for AMIs named "team-alpha-web-server-*" in your account
data "aws_ami" "web_server" {
  most_recent = true
  owners      = ["self"]  # Your AWS account only

  filter {
    name   = "name"
    values = ["${var.ami_name_prefix}*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# Data source: Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Data source: Get available subnets in default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security group for web servers
resource "aws_security_group" "web_server" {
  name        = "${var.app_name}-web-sg"
  description = "Security group for web servers"
  vpc_id      = data.aws_vpc.default.id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.app_name}-web-sg"
    }
  )
}

# Allow inbound HTTP traffic
resource "aws_security_group_rule" "web_server_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.allowed_http_cidrs
  security_group_id = aws_security_group.web_server.id
  description       = "Allow HTTP from specified CIDRs"
}

# Allow inbound HTTPS traffic
resource "aws_security_group_rule" "web_server_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.allowed_http_cidrs
  security_group_id = aws_security_group.web_server.id
  description       = "Allow HTTPS from specified CIDRs"
}

# Allow inbound SSH traffic (for testing/debugging)
resource "aws_security_group_rule" "web_server_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.allowed_ssh_cidrs
  security_group_id = aws_security_group.web_server.id
  description       = "Allow SSH from specified CIDRs"
}

# Allow all outbound traffic
resource "aws_security_group_rule" "web_server_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web_server.id
  description       = "Allow all outbound traffic"
}

# Launch EC2 instances
resource "aws_instance" "web_server" {
  count                = var.instance_count
  ami                  = data.aws_ami.web_server.id
  instance_type        = var.instance_type
  subnet_id            = data.aws_subnets.default.ids[count.index % length(data.aws_subnets.default.ids)]
  vpc_security_group_ids = [aws_security_group.web_server.id]
  iam_instance_profile = var.iam_instance_profile != null ? var.iam_instance_profile : null

  # User data is optional (AMI already has Nginx running)
  # Can be used for additional configuration
  user_data = var.user_data

  # Enable detailed monitoring
  monitoring = var.enable_monitoring

  # Tags
  tags = merge(
    var.common_tags,
    {
      Name = "${var.app_name}-web-${count.index + 1}"
      Role = "web-server"
    }
  )

  # Encrypt root volume
  root_block_device {
    encrypted = var.encrypt_ebs
    volume_size = var.root_volume_size
    volume_type = "gp3"

    tags = merge(
      var.common_tags,
      {
        Name = "${var.app_name}-web-${count.index + 1}-root"
      }
    )
  }

  depends_on = [aws_security_group.web_server]
}

# Elastic IPs for static addressing
resource "aws_eip" "web_server" {
  count    = var.allocate_elastic_ips ? var.instance_count : 0
  instance = aws_instance.web_server[count.index].id
  domain   = "vpc"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.app_name}-eip-${count.index + 1}"
    }
  )

  depends_on = [aws_instance.web_server]
}

# CloudWatch alarms for instance health
resource "aws_cloudwatch_metric_alarm" "instance_status_check" {
  count               = var.enable_monitoring ? var.instance_count : 0
  alarm_name          = "${var.app_name}-instance-${count.index + 1}-status-check"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "Alert when instance status check fails"
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.web_server[count.index].id
  }

  tags = var.common_tags
}
