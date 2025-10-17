variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "key_name" {
  description = "Nombre del key pair para SSH"
  type        = string
  default     = "my-key-pair"  # Cambia esto por tu key pair
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "AMI ID para Ubuntu 22.04"
  type        = string
  default     = "ami-0c7217cdde317cfec"  # Ubuntu 22.04 LTS en us-east-1
}