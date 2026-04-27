terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }

  # Recommended for production: store state in S3 with DynamoDB locking.
  # Uncomment and set your bucket/table names:
  #
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "frappe-lms/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}

# ─── Locals ───────────────────────────────────────────────────────────────────

locals {
  # When no domain is provided, point at the Elastic IP on port 8000 (dev mode)
  base_url = var.domain_name != "" ? "https://${var.domain_name}" : "http://${aws_eip.lms.public_ip}:8000"
}

# ─── Data Sources ─────────────────────────────────────────────────────────────

# Latest Ubuntu 22.04 LTS (Jammy) AMI from Canonical
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's AWS account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Use default VPC (simpler setup; replace with a custom VPC for strict environments)
data "aws_vpc" "default" {
  default = true
}

# ─── SSH Key Pair ──────────────────────────────────────────────────────────────

resource "tls_private_key" "lms" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "lms" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.lms.public_key_openssh

  tags = {
    Name = "${var.project_name}-key"
  }
}

# Private key saved locally — keep this file safe.
# NOTE: Terraform state also holds this key; use a remote backend with encryption.
resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.lms.private_key_pem
  filename        = "${path.module}/${var.project_name}.pem"
  file_permission = "0600"
}

# ─── Security Group ────────────────────────────────────────────────────────────

resource "aws_security_group" "lms" {
  name        = "${var.project_name}-sg"
  description = "Frappe LMS: allow HTTP, HTTPS, and SSH"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "HTTP (redirected to HTTPS by Traefik)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Frappe bench (no-domain test mode)"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg"
  }
}

# ─── EC2 Instance ──────────────────────────────────────────────────────────────

resource "aws_instance" "lms" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.lms.key_name
  vpc_security_group_ids = [aws_security_group.lms.id]

  # Render the bootstrap script with instance-specific values
  user_data = templatefile("${path.module}/user_data.sh", {
    domain_name  = var.domain_name
    admin_email  = var.admin_email
    lms_version  = var.lms_version
    project_name = var.project_name
  })

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size_gb
    delete_on_termination = true
    encrypted             = true
  }

  # Replace the instance (rather than in-place update) if user_data changes
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = var.project_name
  }
}

# ─── Elastic IP ───────────────────────────────────────────────────────────────

resource "aws_eip" "lms" {
  instance = aws_instance.lms.id
  domain   = "vpc"

  # Ensure the instance is fully created before associating
  depends_on = [aws_instance.lms]

  tags = {
    Name = "${var.project_name}-eip"
  }
}

# ─── Route 53 DNS (Optional) ──────────────────────────────────────────────────
# Only created when var.route53_zone_id is provided.

resource "aws_route53_record" "lms" {
  count = var.route53_zone_id != "" ? 1 : 0

  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 60
  records = [aws_eip.lms.public_ip]
}
