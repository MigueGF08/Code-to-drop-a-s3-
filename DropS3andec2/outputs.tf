output "bucket_name" {
  description = "Nombre del bucket S3"
  value       = aws_s3_bucket.photo_bucket.id
}

output "bucket_arn" {
  description = "ARN del bucket S3"
  value       = aws_s3_bucket.photo_bucket.arn
}

output "bucket_url" {
  description = "URL del bucket S3"
  value       = "https://${aws_s3_bucket.photo_bucket.bucket}.s3.amazonaws.com"
}

output "iam_role_name" {
  description = "Nombre del rol IAM"
  value       = aws_iam_role.ec2_s3_role.name
}

output "instance_profile_name" {
  description = "Nombre del instance profile"
  value       = aws_iam_instance_profile.ec2_profile.name
}

output "ec2_public_ip" {
  description = "IP pública de la instancia EC2"
  value       = aws_eip.web_eip.public_ip
}

output "ec2_instance_id" {
  description = "ID de la instancia EC2"
  value       = aws_instance.web_server.id
}

output "web_app_url" {
  description = "URL de la aplicación web"
  value       = "http://${aws_eip.web_eip.public_ip}:8000"
}