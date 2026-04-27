output "elastic_ip" {
  description = "Elastic IP — point your DNS A record here if using a domain"
  value       = aws_eip.lms.public_ip
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.lms.id
}

output "ssh_command" {
  description = "SSH into the instance"
  value       = "ssh -i ${var.project_name}.pem ubuntu@${aws_eip.lms.public_ip}"
}

output "private_key_path" {
  description = "Path to the generated SSH private key"
  value       = local_sensitive_file.private_key.filename
}

output "lms_url" {
  description = "LMS portal URL"
  value       = "${local.base_url}/lms"
}

output "desk_url" {
  description = "Frappe Desk admin backend URL"
  value       = "${local.base_url}/app"
}

output "watch_setup_logs" {
  description = "Stream first-boot setup logs"
  value       = "ssh -i ${var.project_name}.pem ubuntu@${aws_eip.lms.public_ip} 'tail -f /var/log/lms-setup.log'"
}

output "next_steps" {
  description = "What to do after terraform apply"
  value = var.domain_name != "" ? join("\n", [
    "",
    "─── NEXT STEPS (production / domain mode) ───────────────────────────────",
    "",
    "1. Point your DNS A record for '${var.domain_name}' → <elastic_ip from above>",
    "   (Skip if you set route53_zone_id — done automatically)",
    "",
    "2. Wait ~2 minutes for DNS to propagate, then SSH in and run:",
    "     bash /home/ubuntu/deploy-lms.sh",
    "",
    "3. Watch progress (takes ~5-10 min):",
    "     tail -f /var/log/lms-deploy.log",
    "",
    "4. Access:",
    "     LMS portal : https://${var.domain_name}/lms",
    "     Frappe Desk: https://${var.domain_name}/app  (username: Administrator)",
    "─────────────────────────────────────────────────────────────────────────",
  ]) : join("\n", [
    "",
    "─── NEXT STEPS (no-domain test mode) ────────────────────────────────────",
    "",
    "The dev docker-compose is already starting inside the instance.",
    "Bench initialisation takes ~10 minutes on first boot.",
    "",
    "Watch the init logs (SSH in first):",
    "  cd /home/ubuntu/frappe-lms && docker compose logs -f",
    "",
    "Once ready, open in your browser:",
    "  LMS portal : http://<elastic_ip>:8000/lms",
    "  Frappe Desk: http://<elastic_ip>:8000/app",
    "  Username: Administrator  |  Password: admin",
    "",
    "The exact URL with your IP is shown in the 'lms_url' output above.",
    "─────────────────────────────────────────────────────────────────────────",
  ])
}

