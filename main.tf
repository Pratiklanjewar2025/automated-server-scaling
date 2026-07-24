provider "aws" {
  region = "us-east-1"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.16.1"
    }
  }
}

# AWS SSH Key Pair
resource "aws_key_pair" "key" {
  key_name   = "projectkey"
  public_key = file("/home/ubuntu/terraform/projectkey.pub")
}

# Default VPC
resource "aws_default_vpc" "default_vpc" {
}

# Security Group
resource "aws_security_group" "allow_sshv4" {

  name   = "allow_sshv4"
  vpc_id = aws_default_vpc.default_vpc.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Flask Application
  ingress {
    from_port   = 5000
    to_port     = 5000
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

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outgoing Traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Ubuntu AMI
variable "ami_id" {
  description = "Ubuntu AMI ID"
  default     = "YOUR_AMI_ID"
}

# Number of EC2 Instances
variable "instance_count" {
  description = "Number of instances"
  default     = 1
}

# EC2 Instances
resource "aws_instance" "my_ec2" {

  count = var.instance_count

  ami           = var.ami_id
  instance_type = "t2.micro"

  key_name = aws_key_pair.key.key_name

  security_groups = [
    aws_security_group.allow_sshv4.name
  ]

  associate_public_ip_address = true

  tags = {
    Name = "new-server-${count.index + 1}"
  }

  provisioner "local-exec" {
    command = "echo '${self.public_ip}' >> ip_save.txt"
  }
}

# All EC2 Public IPs
output "public_ips" {
  value = aws_instance.my_ec2[*].public_ip
}

# Latest EC2 Public IP
output "latest_instance_ip" {

  value = element(
    aws_instance.my_ec2[*].public_ip,
    length(aws_instance.my_ec2) - 1
  )
}
