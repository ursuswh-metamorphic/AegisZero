# =============================================================================
# AEGIS PORTAL – DỮ LIỆU ĐẦU VÀO ĐƯỢC GENERATE TỰ ĐỘNG (HYBRID)
# =============================================================================

project_name       = "{{ values.project_name }}"
environment        = "{{ values.environment }}"

# ── AWS Parameters ───────────────────────────────────────────────────────────
aws_vpc_cidr       = "{{ values.aws_vpc_cidr }}"
aws_subnet_cidr    = "{{ values.aws_subnet_cidr }}"
aws_instance_type  = "{{ values.aws_instance_type }}"
aws_ebs_size       = {{ values.aws_ebs_size }}
aws_ebs_encrypted  = {{ values.aws_ebs_encrypted }}
aws_iam_admin_role = {{ values.aws_iam_admin_role }}
aws_inbound_ports  = [{{ values.aws_inbound_ports | join(',') }}]

# ── OpenStack Parameters ──────────────────────────────────────────────────────
os_network_name    = "{{ values.os_network_name }}"
os_subnet_cidr     = "{{ values.os_subnet_cidr }}"
os_db_port         = {{ values.os_db_port }}
os_db_allowed_cidr = "{{ values.os_db_allowed_cidr }}"
os_flavor_name     = "{{ values.os_flavor_name }}"