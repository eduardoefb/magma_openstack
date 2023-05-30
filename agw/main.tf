terraform {
required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "1.47.0"
    }
  }
}


####### DNS Configuration ###################################

####### AGW Instance #######################################
resource "openstack_networking_secgroup_v2" "agw_secgroup" {
  name        = "agw_secgroup"
  description = "Security group for agw"
}

resource "openstack_networking_secgroup_rule_v2" "k8s_tcp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 65535
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.agw_secgroup.id}"
}

resource "openstack_networking_secgroup_rule_v2" "k8s_udp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 22
  port_range_max    = 65535
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.agw_secgroup.id}"
}

resource "openstack_networking_secgroup_rule_v2" "k8s_udp_out" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 22
  port_range_max    = 65535
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.agw_secgroup.id}"
}

resource "openstack_networking_secgroup_rule_v2" "k8s_sctp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "sctp"
  port_range_min    = "38412"
  port_range_max    = "38412"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.agw_secgroup.id}"
}

resource "openstack_networking_secgroup_rule_v2" "k8s_sctp2" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "sctp"
  port_range_min    = "38412"
  port_range_max    = "38412"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.agw_secgroup.id}"
}

data "openstack_networking_network_v2" "oam_network" {
  name = var.oam_network
}

data openstack_networking_subnet_v2 oam_subnet {
    name = var.oam_subnet
}

data "openstack_networking_network_v2" "s1_network" {
  name = var.s1_network
}

data openstack_networking_subnet_v2 s1_subnet {
    name = var.s1_subnet
}

resource "openstack_compute_keypair_v2" "agw" {
  name          = "agw"
  public_key    = file("${var.key_pair_file}")
}

resource "openstack_networking_port_v2" "port" {
  
  name           = "agw_s1_port"
  network_id     = "${data.openstack_networking_network_v2.s1_network.id}"
  admin_state_up = "true"

  fixed_ip {
    ip_address = "10.3.0.155"
    subnet_id = data.openstack_networking_subnet_v2.s1_subnet.id
  }  

}

resource "openstack_compute_instance_v2" "agw" {
  name            = "agw01"
  flavor_name     = "m1.large"
  image_name      = "ubuntu_20.04"
  key_pair        = "agw"
  # availability_zone = "zone03"
  security_groups = [ openstack_networking_secgroup_v2.agw_secgroup.name ]
  network {
    name = var.oam_network
  }

  network {
    port   = openstack_networking_port_v2.port.id
  }

  depends_on = [
    openstack_networking_secgroup_v2.agw_secgroup
  ]
}


resource "null_resource" "floating_ip_output" {
  depends_on = [openstack_compute_instance_v2.agw]

  provisioner "local-exec" {
    command = "echo '${openstack_compute_instance_v2.agw.access_ip_v4}' > oam_ip.txt"
  }
}

resource "null_resource" "instance_name_output" {
  depends_on = [openstack_compute_instance_v2.agw]

  provisioner "local-exec" {
    command = "echo '${openstack_compute_instance_v2.agw.name}' > instance_name.txt"
  }
}


#################Variables##########################################


variable "oam_subnet"{
    description = "External network name"
}

variable "oam_network"{
    description = "External network name"
}

variable "s1_subnet"{
    description = "External network name"
}

variable "s1_network"{
    description = "External network name"
}

variable "key_pair_file"{
  description = "Public key file"
}


