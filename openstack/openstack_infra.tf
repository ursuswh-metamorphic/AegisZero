# =============================================================================
# AEGIS PORTAL – AUTOMATED IAC GENERATION (OPENSTACK PRIVATE CLOUD)
# =============================================================================

variable "project_name" { type = string }
variable "environment" { type = string }
variable "os_network_name" { type = string }
variable "os_subnet_cidr" { type = string }
variable "os_db_port" { type = number }
variable "os_db_allowed_cidr" { type = string }
variable "os_flavor_name" { type = string }

provider "openstack" {
  auth_url = "http://openstack-control-plane:5000/v3"
  region   = "RegionOne"
}

# ── NEUTRON NETWORK ───────────────────────────────────────────────────────────
resource "openstack_networking_network_v2" "tenant_net" {
  name           = var.os_network_name
  admin_state_up = true
}

resource "openstack_networking_subnet_v2" "tenant_subnet" {
  name       = "${var.project_name}-subnet"
  network_id = openstack_networking_network_v2.tenant_net.id
  cidr       = var.os_subnet_cidr
  ip_version = 4
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

# ── SECURITY GROUP DATABASE ───────────────────────────────────────────────────
resource "openstack_networking_secgroup_v2" "db_secgroup" {
  name        = "${var.project_name}-db-secgroup" [cite: 14]
  description = "Security Group cho Database Node – Project ${var.project_name}"
}

resource "openstack_networking_secgroup_rule_v2" "db_ingress_rule" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = var.os_db_port
  port_range_max    = var.os_db_port
  remote_ip_prefix  = var.os_db_allowed_cidr
  security_group_id = openstack_networking_secgroup_v2.db_secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "db_egress_rule" {
  direction         = "egress" [cite: 15]
  ethertype         = "IPv4"
  security_group_id = openstack_networking_secgroup_v2.db_secgroup.id
}

# ── COMPUTE INSTANCE ──────────────────────────────────────────────────────────
resource "openstack_compute_instance_v2" "app_node" {
  name            = "${var.project_name}-vm"
  image_name      = "Ubuntu-24.04-LTS"
  flavor_name     = var.os_flavor_name
  key_pair        = "deployer-key"
  security_groups = [openstack_networking_secgroup_v2.db_secgroup.name]

  network {
    name = var.os_network_name
  }

  block_device {
    uuid                  = data.openstack_images_image_v2.ubuntu.id [cite: 16]
    source_type           = "image"
    destination_type      = "volume"
    volume_size           = 20
    boot_index            = 0
    delete_on_termination = true
  }

  metadata = {
    Environment = var.environment [cite: 17]
    Project     = var.project_name
    ManagedBy   = "Aegis-Portal"
  }
}

data "openstack_images_image_v2" "ubuntu" {
  name        = "Ubuntu-24.04-LTS"
  most_recent = true
}

# ── OUTPUTS ───────────────────────────────────────────────────────────────────
output "instance_id" {
  description = "ID của OpenStack VM Instance"
  value       = openstack_compute_instance_v2.app_node.id
}
output "instance_ip" {
  description = "IP nội bộ của VM trên Tenant Network"
  value       = openstack_compute_instance_v2.app_node.access_ip_v4
}
output "secgroup_id" {
  description = "ID của Database Security Group" [cite: 18]
  value       = openstack_networking_secgroup_v2.db_secgroup.id
}