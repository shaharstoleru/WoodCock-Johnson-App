output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public_a.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.web.id
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.app.id
}

# הוראות למציאת ה-IP
output "how_to_find_ip" {
  description = "Commands to find your website IP"
  value = <<-EOT

  🚀 כדי למצוא את ה-IP של האתר שלך, רוץ:

  aws ec2 describe-instances \
    --region ${var.aws_region} \
    --filters "Name=tag:Name,Values=${var.project_name}-instance" "Name=instance-state-name,Values=running" \
    --query 'Reservations[*].Instances[*].[PublicIpAddress,InstanceId,State.Name]' \
    --output table

  או בדוק ב-AWS Console:
  EC2 → Instances → חפש "${var.project_name}-instance"

  EOT
}

# Region info
output "website_region" {
  description = "AWS region where your website is running"
  value       = var.aws_region
}