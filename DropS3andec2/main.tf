terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# S3 Bucket para almacenar fotos
resource "aws_s3_bucket" "photo_bucket" {
  bucket = "photo-upload-bucket-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "Photo Upload Bucket"
    Environment = "Dev"
  }
}

# Generar un sufijo aleatorio para el nombre del bucket
resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# Configuración de acceso público del bucket
resource "aws_s3_bucket_public_access_block" "photo_bucket_pab" {
  bucket = aws_s3_bucket.photo_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Política del bucket para permitir lectura pública
resource "aws_s3_bucket_policy" "photo_bucket_policy" {
  bucket = aws_s3_bucket.photo_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.photo_bucket.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.photo_bucket_pab]
}

# Configuración de CORS para el bucket
resource "aws_s3_bucket_cors_configuration" "photo_bucket_cors" {
  bucket = aws_s3_bucket.photo_bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# IAM Role para EC2
resource "aws_iam_role" "ec2_s3_role" {
  name = "ec2-s3-upload-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Política IAM para permitir upload a S3
resource "aws_iam_role_policy" "ec2_s3_policy" {
  name = "ec2-s3-upload-policy"
  role = aws_iam_role.ec2_s3_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.photo_bucket.arn,
          "${aws_s3_bucket.photo_bucket.arn}/*"
        ]
      }
    ]
  })
}

# Instance Profile para EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-s3-upload-profile"
  role = aws_iam_role.ec2_s3_role.name
}

# Security Group para la instancia EC2
resource "aws_security_group" "web_sg" {
  name        = "web-server-sg"
  description = "Security group for web server"

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Puerto 8000 para Python HTTP Server
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Salida a internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-server-sg"
  }
}

# Instancia EC2
resource "aws_instance" "web_server" {
  ami           = "ami-0c7217cdde317cfec"  # Ubuntu 22.04 LTS en us-east-1
  instance_type = "t2.micro"
  
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  
  # Crea o usa tu key pair existente
  key_name = "my-key-pair"  # CAMBIA esto por el nombre de tu key pair

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y python3 python3-pip unzip
              
              # Instalar Terraform
              wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
              echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
              apt-get update && apt-get install -y terraform
              
              # Crear directorio para la aplicación
              mkdir -p /home/ubuntu/app
              chown -R ubuntu:ubuntu /home/ubuntu/app
              EOF

  tags = {
    Name = "Web-Server-S3-Upload"
  }
}

# Elastic IP (opcional pero recomendado)
resource "aws_eip" "web_eip" {
  instance = aws_instance.web_server.id
  domain   = "vpc"

  tags = {
    Name = "web-server-eip"
  }
}