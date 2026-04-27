variable "aws_region" {
  description = "AWS region to deploy in"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for all resource naming and tagging"
  type        = string
  default     = "frappe-lms"
}

variable "instance_type" {
  description = "EC2 instance type. t3.medium is minimum (2 vCPU, 4 GB RAM)"
  type        = string
  default     = "t3.medium"
}

variable "domain_name" {
  description = "Fully qualified domain name for the LMS (e.g. lms.yourdomain.com). Leave empty to run in no-domain test mode — site will be accessible at http://IP:8000"
  type        = string
  default     = ""
}

variable "admin_email" {
  description = "Admin email for Let's Encrypt SSL. Required only when domain_name is set."
  type        = string
  default     = ""
}

variable "lms_version" {
  description = "Frappe LMS version to deploy: 'stable', 'develop', or a specific git tag"
  type        = string
  default     = "stable"
}

variable "root_volume_size_gb" {
  description = "Root EBS volume size in GB (gp3)"
  type        = number
  default     = 30
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH into the instance. Restrict to your IP for security, e.g. 1.2.3.4/32"
  type        = string
  default     = "0.0.0.0/0"
}

variable "route53_zone_id" {
  description = "(Optional) Route 53 hosted zone ID. If set, an A record pointing to the Elastic IP will be created automatically."
  type        = string
  default     = ""
}
