terraform {
required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "1.47.0"
    }
  }
}

resource "openstack_networking_network_v2" "network" {
  name = "${var.environment.prefix}_int_net"
}

resource "openstack_networking_subnet_v2" "subnet" {
  name            = "${var.environment.prefix}_int_sub"
  network_id      = openstack_networking_network_v2.network.id
  cidr            = var.environment.internal_subnet_cidr
  gateway_ip      = var.environment.internal_subnet_gw
  dns_nameservers = var.environment.dns_nameservers

}

resource "openstack_compute_keypair_v2" "keypair" {
  name          = "${var.environment.prefix}"
  public_key    = file(var.environment.public_key)
}

data "openstack_networking_network_v2" "ext_net"{
  name = var.environment.external_network
}

data "openstack_networking_subnet_v2" "ext_sub_net"{
  name = var.environment.external_subnet
}

data openstack_images_image_v2 image_01 {
  name = var.environment.bastian_image
}

# Router
resource "openstack_networking_router_v2" "router" {
  name                = "${var.environment.prefix}-router"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.ext_net.id
  depends_on = [
      openstack_networking_subnet_v2.subnet,
      openstack_networking_network_v2.network,
  ]
}

resource "openstack_networking_router_interface_v2" "router_interface_01" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.subnet.id

  depends_on = [
      openstack_networking_subnet_v2.subnet,
      openstack_networking_network_v2.network,
      openstack_networking_router_v2.router
  ]
}


resource "openstack_networking_secgroup_v2" "k8s_secgroup" {
  name        = "magma_secgroup"
  description = "Security group for k8s"
}

resource "openstack_networking_secgroup_rule_v2" "k8s_tcp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 65535
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.k8s_secgroup.id}"
}

resource "openstack_networking_secgroup_rule_v2" "k8s_udp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 22
  port_range_max    = 65535
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.k8s_secgroup.id}"
}

resource "openstack_networking_secgroup_rule_v2" "k8s_udp_out" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 22
  port_range_max    = 65535
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.k8s_secgroup.id}"
}

resource "openstack_networking_secgroup_rule_v2" "k8s_sctp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "sctp"
  port_range_min    = "38412"
  port_range_max    = "38412"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.k8s_secgroup.id}"
}

resource "openstack_networking_secgroup_rule_v2" "k8s_sctp2" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "sctp"
  port_range_min    = "38412"
  port_range_max    = "38412"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.k8s_secgroup.id}"
}


#########################################################################################################
#     Bastian node
#########################################################################################################
resource "openstack_compute_instance_v2" "bastian" {
  name            = "${var.environment.prefix}-bastian"
  flavor_name     = var.environment.bastian_flavor
  image_name      = var.environment.bastian_image
  key_pair        = openstack_compute_keypair_v2.keypair.name
  availability_zone = var.environment.bastian_az
  security_groups = [ openstack_networking_secgroup_v2.k8s_secgroup.name ]
  network {
    name = openstack_networking_network_v2.network.name
  }

  depends_on = [
    openstack_networking_network_v2.network,
    openstack_networking_subnet_v2.subnet,
    openstack_networking_router_interface_v2.router_interface_01
  ]
}

# Create a list of floating IPs
resource "openstack_networking_floatingip_v2" "bastian_floating_ip" {
  pool  = var.environment.external_network
  subnet_id = data.openstack_networking_subnet_v2.ext_sub_net.id
}

# Associate floating IPs with instances
resource "openstack_compute_floatingip_associate_v2" "bastian_floating_ip_associate" {
  floating_ip     = openstack_networking_floatingip_v2.bastian_floating_ip.address
  fixed_ip        = openstack_compute_instance_v2.bastian.network.0.fixed_ip_v4
  instance_id     = openstack_compute_instance_v2.bastian.id
  depends_on      = [openstack_compute_instance_v2.bastian, openstack_networking_floatingip_v2.bastian_floating_ip]
}

#########################################################################################################
# Domain and recordsets
#########################################################################################################
resource "openstack_dns_zone_v2" "zone" {
  name        = var.environment.domain
  email       = "foo@foo.com"
  description = "An example zone"
  ttl         = 3000
  type        = "PRIMARY"
}

# Bastian
resource "openstack_dns_recordset_v2" "bastian" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "${openstack_compute_instance_v2.bastian.name}.${var.environment.domain}"
  description = "Recordset k8s"
  ttl         = 3000
  type        = "A"
  #records     = [ openstack_compute_instance_v2.bastian.access_ip_v4 ]
  records     = [ openstack_networking_floatingip_v2.bastian_floating_ip.address ]
}


####### AGW Instance #######################################
resource "openstack_networking_secgroup_v2" "agw_secgroup" {
  name        = "agw_secgroup"
  description = "Security group for agw"
}

resource "openstack_networking_secgroup_rule_v2" "agw_tcp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 65535
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.agw_secgroup.id}"
}

resource "openstack_networking_secgroup_rule_v2" "agw_udp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 22
  port_range_max    = 65535
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.agw_secgroup.id}"
}

resource "openstack_networking_secgroup_rule_v2" "agw_udp_out" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 22
  port_range_max    = 65535
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.agw_secgroup.id}"
}

resource "openstack_networking_secgroup_rule_v2" "agw_sctp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "sctp"
  port_range_min    = "38412"
  port_range_max    = "38412"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.agw_secgroup.id}"
}

resource "openstack_networking_secgroup_rule_v2" "agw_sctp2" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "sctp"
  port_range_min    = "38412"
  port_range_max    = "38412"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.agw_secgroup.id}"
}

data "openstack_networking_network_v2" "oam_network" {
  name = var.environment.external_network
}

data openstack_networking_subnet_v2 oam_subnet {
    name = var.environment.external_subnet
}

data "openstack_networking_network_v2" "s1_network" {
  name = var.environment.s1_network
}

data openstack_networking_subnet_v2 s1_subnet {
    name = var.environment.s1_subnet
}

resource "openstack_networking_port_v2" "port" {
  
  name           = "agw_s1_port"
  network_id     = "${data.openstack_networking_network_v2.s1_network.id}"
  admin_state_up = "true"

  fixed_ip {
    ip_address = var.environment.s1_agw_ip
    subnet_id = data.openstack_networking_subnet_v2.s1_subnet.id
  }  

}

resource "openstack_compute_instance_v2" "agw" {
  name            = "${var.environment.prefix}-agw01"
  flavor_name     = var.environment.agw_flavor
  image_name      = "${var.environment.agw_image}"
  key_pair        = openstack_compute_keypair_v2.keypair.name
  availability_zone = var.environment.agw_az
  security_groups = [ openstack_networking_secgroup_v2.agw_secgroup.name ]

  # OAM Network
  network {
    name = openstack_networking_network_v2.network.name
  }

  # S1 network
  network {
    port   = openstack_networking_port_v2.port.id
  }

  depends_on = [
    openstack_networking_secgroup_v2.agw_secgroup,
    openstack_networking_network_v2.network,
    openstack_networking_subnet_v2.subnet,
    openstack_networking_router_interface_v2.router_interface_01    
  ]
}

# Create a list of floating IPs
resource "openstack_networking_floatingip_v2" "agw_floating_ip" {
  pool  = var.environment.external_network
  subnet_id = data.openstack_networking_subnet_v2.ext_sub_net.id
}

# Associate floating IPs with instances
resource "openstack_compute_floatingip_associate_v2" "agw_floating_ip_associate" {
  floating_ip     = openstack_networking_floatingip_v2.agw_floating_ip.address
  fixed_ip        = openstack_compute_instance_v2.agw.network.0.fixed_ip_v4
  instance_id     = openstack_compute_instance_v2.agw.id
  depends_on      = [openstack_compute_instance_v2.agw, openstack_networking_floatingip_v2.agw_floating_ip]
}



#########################################################################################################
# Output:
#########################################################################################################


resource "local_file" "bastian" {
  filename = "bastian.txt"
  content  = "${openstack_compute_instance_v2.bastian.id} ${openstack_compute_instance_v2.bastian.name} ${openstack_compute_instance_v2.bastian.access_ip_v4}"
}

resource "local_file" "agw" {
  filename = "agw.txt"
  content  = "${openstack_compute_instance_v2.agw.id} ${openstack_compute_instance_v2.agw.name} ${openstack_compute_instance_v2.agw.access_ip_v4}"
}

resource "local_file" "domain"{
  filename = "domain.txt"
  content = "${var.environment.domain}"
}

resource "local_file" "int_network"{
  filename = "int_network.txt"
  content = "${var.environment.internal_subnet_cidr}"
}

resource "local_file" "dns" {
  filename = "dns.txt"
  content  = join("\n", [for dns in var.environment.dns_nameservers : "${dns}"])
}

resource "local_file" "internal_subnet_id" {
  content  = "${openstack_networking_subnet_v2.subnet.id}"
  filename = "internal_subnet_id.txt"
}
