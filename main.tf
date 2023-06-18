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

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
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
  port_range_min    = "36412"
  port_range_max    = "36412"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.k8s_secgroup.id}"
}

resource "openstack_networking_secgroup_rule_v2" "k8s_sctp2" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "sctp"
  port_range_min    = "36412"
  port_range_max    = "36412"
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
  description = "Recordset bastian"
  ttl         = 3000
  type        = "A"  
  records     = [ openstack_networking_floatingip_v2.bastian_floating_ip.address ]
}


# Magma dns entries
resource "openstack_dns_recordset_v2" "bootstrapper-controller" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "bootstrapper-controller.${var.environment.domain}"
  description = "bootstrapper"
  ttl         = 3000
  type        = "A"
  records     = [ "${var.bootstrapper}" ]

}

resource "openstack_dns_recordset_v2" "api" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "api.${var.environment.domain}"
  description = "api"
  ttl         = 3000
  type        = "A"
  records     = [ "${var.api}" ]

}

resource "openstack_dns_recordset_v2" "controller" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "controller.${var.environment.domain}"
  description = "controller"
  ttl         = 3000
  type        = "A"
  records     = [ "${var.controller}" ]


}

resource "openstack_dns_recordset_v2" "nms" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "*.nms.${var.environment.domain}"
  description = "nms"
  ttl         = 3000
  type        = "A"
  records     = [ "${var.nms}" ]

}

resource "openstack_dns_recordset_v2" "nms_host" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "host.nms.${var.environment.domain}"
  description = "nms"
  ttl         = 3000
  type        = "A"
  records     = [ "${var.nms}" ]

}

resource "openstack_dns_recordset_v2" "nms_custom" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "custom.nms.${var.environment.domain}"
  description = "nms"
  ttl         = 3000
  type        = "A"
  records     = [ "${var.nms}" ]

}

resource "openstack_dns_recordset_v2" "fluentd" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "fluentd.${var.environment.domain}"
  description = "fluentd"
  ttl         = 3000
  type        = "A"
  records     = [ "${var.fluentd}" ]

}

resource "openstack_dns_recordset_v2" "kibana" {
  zone_id     = openstack_dns_zone_v2.zone.id
  name        = "kibana.${var.environment.domain}"
  description = "kibana"
  ttl         = 3000
  type        = "A"
  records     = [ "${var.kibana}" ]

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
  port_range_min    = "36412"
  port_range_max    = "36412"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.agw_secgroup.id}"
}

resource "openstack_networking_secgroup_rule_v2" "agw_sctp2" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "sctp"
  port_range_min    = "36412"
  port_range_max    = "36412"
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
    name = data.openstack_networking_network_v2.s1_network.name
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


########################################################################################################
# Enodeb 
########################################################################################################

resource "openstack_networking_secgroup_v2" "enodeb_secgroup" {
  count       = var.create_ran ? 1:0
  name        = "enodeb_secgroup"
  description = "Security group for enodeb"
}

resource "openstack_networking_secgroup_rule_v2" "enodeb_tcp" {
  count             = var.create_ran ? 1:0
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 65535
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.enodeb_secgroup.0.id}"
}

resource "openstack_networking_secgroup_rule_v2" "enodeb_udp" {
  count             = var.create_ran ? 1:0
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 22
  port_range_max    = 65535
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.enodeb_secgroup.0.id}"
}

resource "openstack_networking_secgroup_rule_v2" "enodeb_udp_out" {
  count             = var.create_ran ? 1:0
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 22
  port_range_max    = 65535
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.enodeb_secgroup.0.id}"
}

resource "openstack_networking_secgroup_rule_v2" "enodeb_sctp" {
  count             = var.create_ran ? 1:0
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "sctp"
  port_range_min    = "36412"
  port_range_max    = "36412"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.enodeb_secgroup.0.id}"
}

resource "openstack_networking_secgroup_rule_v2" "enodeb_sctp2" {
  count             = var.create_ran ? 1:0
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "sctp"
  port_range_min    = "36412"
  port_range_max    = "36412"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.enodeb_secgroup.0.id}"
}


resource "openstack_compute_instance_v2" "enodeb" {
  count           = var.create_ran ? 1:0
  name            = "${var.environment.prefix}-enodeb01"
  flavor_name     = var.environment.enodeb_flavor
  image_name      = "${var.environment.enodeb_image}"
  key_pair        = openstack_compute_keypair_v2.keypair.name
  availability_zone = var.environment.enodeb_az
  security_groups = [ openstack_networking_secgroup_v2.enodeb_secgroup.0.name ]

  # OAM Network
  network {
    name = openstack_networking_network_v2.network.name
  }

  # S1 network
  network {
    name = data.openstack_networking_network_v2.s1_network.name
  }

  depends_on = [
    openstack_networking_secgroup_v2.agw_secgroup,
    openstack_networking_network_v2.network,
    openstack_networking_subnet_v2.subnet,
    openstack_networking_router_interface_v2.router_interface_01    
  ]
}

# Create a list of floating IPs
resource "openstack_networking_floatingip_v2" "enodeb_floating_ip" {
  count         = var.create_ran ? 1:0
  pool          = var.environment.external_network
  subnet_id     = data.openstack_networking_subnet_v2.ext_sub_net.id
}

# Associate floating IPs with instances
resource "openstack_compute_floatingip_associate_v2" "enodeb_floating_ip_associate" {
  count           = var.create_ran ? 1:0
  floating_ip     = openstack_networking_floatingip_v2.enodeb_floating_ip.0.address
  fixed_ip        = openstack_compute_instance_v2.enodeb.0.network.0.fixed_ip_v4
  instance_id     = openstack_compute_instance_v2.enodeb.0.id
  depends_on      = [openstack_compute_instance_v2.enodeb, openstack_networking_floatingip_v2.enodeb_floating_ip]
}

########################################################################################################
# UE
########################################################################################################

resource "openstack_compute_instance_v2" "ue" {
  count             = var.create_ran ? 1:0
  name              = "${var.environment.prefix}-ue01"
  flavor_name       = var.environment.ue_flavor
  image_name        = "${var.environment.ue_image}"
  key_pair          = openstack_compute_keypair_v2.keypair.name
  availability_zone = var.environment.ue_az
  security_groups   = [ openstack_networking_secgroup_v2.enodeb_secgroup.0.name ]

  # OAM Network
  network {
    name = openstack_networking_network_v2.network.name
  }

  depends_on = [
    openstack_networking_secgroup_v2.agw_secgroup,
    openstack_networking_network_v2.network,
    openstack_networking_subnet_v2.subnet,
    openstack_networking_router_interface_v2.router_interface_01    
  ]
}

# Create a list of floating IPs
resource "openstack_networking_floatingip_v2" "ue_floating_ip" {
  count       = var.create_ran ? 1:0
  pool        = var.environment.external_network
  subnet_id   = data.openstack_networking_subnet_v2.ext_sub_net.id
}

# Associate floating IPs with instances
resource "openstack_compute_floatingip_associate_v2" "ue_floating_ip_associate" {
  count           = var.create_ran ? 1:0
  floating_ip     = openstack_networking_floatingip_v2.ue_floating_ip.0.address
  fixed_ip        = openstack_compute_instance_v2.ue.0.network.0.fixed_ip_v4
  instance_id     = openstack_compute_instance_v2.ue.0.id
  depends_on      = [openstack_compute_instance_v2.ue, openstack_networking_floatingip_v2.ue_floating_ip]
}


#########################################################################################################
# Output:
#########################################################################################################

## Floating ips:
resource "local_file" "bastian_floating_ip" {
  filename = "bastian_floating_ip.txt"
  content  = "${openstack_networking_floatingip_v2.bastian_floating_ip.address}"
}

resource "local_file" "agw_floating_ip" {
  filename = "agw_floating_ip.txt"
  content  = "${openstack_networking_floatingip_v2.agw_floating_ip.address}"
}

resource "local_file" "enodeb_floating_ip" {
  filename = "enodeb_floating_ip.txt"
  content  = "${openstack_networking_floatingip_v2.enodeb_floating_ip.0.address}"
}

resource "local_file" "ue_floating_ip" {
  filename = "ue_floating_ip.txt"
  content  = "${openstack_networking_floatingip_v2.ue_floating_ip.0.address}"
}

#### Instances
resource "local_file" "bastian" {
  filename = "bastian.txt"
  content  = "${openstack_compute_instance_v2.bastian.id} ${openstack_compute_instance_v2.bastian.name} ${openstack_compute_instance_v2.bastian.access_ip_v4}"
}

resource "local_file" "agw" {
  filename = "agw.txt"
  content  = "${openstack_compute_instance_v2.agw.id} ${openstack_compute_instance_v2.agw.name} ${openstack_compute_instance_v2.agw.access_ip_v4}"
}

resource "local_file" "enodeb" {
  count    = var.create_ran ? 1:0
  filename = "enodeb.txt"
  content  = "${openstack_compute_instance_v2.enodeb.0.id} ${openstack_compute_instance_v2.enodeb.0.name} ${openstack_compute_instance_v2.enodeb.0.access_ip_v4}"
}

resource "local_file" "ue" {
  count     = var.create_ran ? 1:0
  filename  = "ue.txt"
  content   = "${openstack_compute_instance_v2.ue.0.id} ${openstack_compute_instance_v2.ue.0.name} ${openstack_compute_instance_v2.ue.0.access_ip_v4}"
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

resource "local_file" "agw_s1_ip"{
  content = "${openstack_compute_instance_v2.agw.network.1.fixed_ip_v4}"
  filename = "agw_s1_ip.txt"
}

resource "local_file" "enodeb_s1_ip"{
  count     = var.create_ran ? 1:0
  content   = "${openstack_compute_instance_v2.enodeb.0.network.1.fixed_ip_v4}"
  filename  = "enodeb_s1_ip.txt"
}

resource "local_file" "agw_s1_subnet"{
  content   = "${var.environment.s1_subnet}"
  filename  = "agw_s1_subnet.txt"
}

resource "local_file" "s1_subnet_cidr"{
  content   = "${data.openstack_networking_subnet_v2.s1_subnet.cidr}"
  filename  = "s1_subnet_cidr.txt"
}

