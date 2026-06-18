# =============================================================================
# SẢN PHẨM ĐÚC RA TỪ AEGIS PORTAL
# DỰ ÁN : AWS INFRASTRUCTURE
# =============================================================================

variable "project_name" { type = string }
variable "environment" { type = string }
variable "aws_vpc_cidr" { type = string }
variable "aws_subnet_cidr" { type = string }
variable "aws_instance_type" { type = string }
variable "aws_ebs_size" { type = number }
variable "aws_ebs_encrypted" { type = bool }
variable "aws_iam_admin_role" { type = bool }
variable "aws_inbound_ports" { type = list(number) }

provider "aws" {
  region = "ap-southeast-1"
}

# ── VPC ───────────────────────────────────────────────────────────────────────
resource "aws_vpc" "aws_hybrid_vpc" {
  cidr_block           = var.aws_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
    ManagedBy   = "Aegis-Portal-Terraform"
  }
}

# ── SUBNET ────────────────────────────────────────────────────────────────────
resource "aws_subnet" "aws_public_subnet" {
  vpc_id                  = aws_vpc.aws_hybrid_vpc.id [cite: 3]
  cidr_block              = var.aws_subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet"
    Environment = var.environment
  }
}

# ── INTERNET GATEWAY ──────────────────────────────────────────────────────────
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.aws_hybrid_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# ── SECURITY GROUP ────────────────────────────────────────────────────────────
resource "aws_security_group" "app_sg" {
  name        = "${var.project_name}-app-sg" [cite: 4]
  description = "Security Group for ${var.project_name} (${var.environment})"
  vpc_id      = aws_vpc.aws_hybrid_vpc.id

  # Sử dụng dynamic block thuần của Terraform để thay thế vòng lặp Jinja2 cũ
  dynamic "ingress" {
    for_each = var.aws_inbound_ports
    content {
      description = "Port ${ingress.value} – opened via Aegis Portal"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0 [cite: 5]
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name        = "${var.project_name}-app-sg"
    Environment = var.environment
  }
}

# ── EC2 INSTANCE ──────────────────────────────────────────────────────────────
resource "aws_instance" "app_node" {
  ami                    = "ami-0e472ba40eb589f49"
  instance_type          = var.aws_instance_type [cite: 6]
  subnet_id              = aws_subnet.aws_public_subnet.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  ebs_block_device {
    device_name = "/dev/sdb"
    volume_size = var.aws_ebs_size
    encrypted   = var.aws_ebs_encrypted [cite: 7]

    tags = {
      Name = "${var.project_name}-data-disk"
    }
  }

  # Sử dụng toán tử điều kiện động của Terraform để ẩn/hiện cấu hình
  iam_instance_profile = var.aws_iam_admin_role ? aws_iam_instance_profile.admin_profile[0].name : null

  tags = {
    Name        = "${var.project_name}-ec2"
    Environment = var.environment
    ManagedBy   = "Aegis-Portal-Terraform"
  }
}

# ── IAM INSTANCE PROFILE ──────────────────────────────────────────────────────
resource "aws_iam_role" "ec2_admin_role" {
  count = var.aws_iam_admin_role ? 1 : 0
  name  = "${var.project_name}-ec2-admin-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17" [cite: 8]
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = {
    Environment       = var.environment
    AegisSecurityNote = "AdminRoleAttached-ReviewRequired"
  }
}

resource "aws_iam_role_policy_attachment" "admin_attach" {
  count      = var.aws_iam_admin_role ? 1 : 0
  role       = aws_iam_role.ec2_admin_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "admin_profile" {
  count = var.aws_iam_admin_role ? 1 : 0
  name  = "${var.project_name}-admin-profile"
  role  = aws_iam_role.ec2_admin_role[0].name [cite: 9]
}

# ── OUTPUTS ───────────────────────────────────────────────────────────────────
output "vpc_id" {
  description = "ID của VPC vừa tạo"
  value       = aws_vpc.aws_hybrid_vpc.id
}
output "instance_id" {
  description = "ID của EC2 Instance"
  value       = aws_instance.app_node.id
}
output "security_group_id" {
  description = "ID của Security Group"
  value       = aws_security_group.app_sg.id
}