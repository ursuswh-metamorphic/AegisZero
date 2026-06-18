# =============================================================================
# AEGIS PORTAL – DỮ LIỆU ĐẦU VÀO ĐƯỢC GENERATE TỰ ĐỘNG (HYBRID - FORGED BY NODEJS)
# =============================================================================

project_name       = "aegis"
environment        = "staging"

# ── AWS Parameters ───────────────────────────────────────────────────────────
aws_vpc_cidr       = "10.10.0.0/16"
aws_subnet_cidr    = "10.10.1.0/24"
aws_instance_type  = "t3.micro"
aws_ebs_size       = 20
aws_ebs_encrypted  = true
aws_iam_admin_role = false
aws_inbound_ports  = [80,443]

# ── OpenStack Parameters ──────────────────────────────────────────────────────
os_network_name    = "os-internal-network"
os_subnet_cidr     = "192.168.10.0/24"
os_db_port         = 3306
os_db_allowed_cidr = "10.10.0.0/16"
os_flavor_name     = "m1.medium"
