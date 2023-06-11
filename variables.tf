variable environment {
    type =  object({
                    prefix = string, 
                     public_key = string, 
                     bastian_image = string, 
                     agw_image = string,
                     s1_network = string,
                     s1_subnet = string,
                     s1_agw_ip = string,
                     internal_subnet_cidr = string,
                     external_network = string,
                     internal_subnet_gw = string,
                     dns_nameservers = list(string),
                     external_subnet = string,
                     bastian_flavor = string,
                     agw_flavor = string,
                     bastian_az = string,
                     gnodeb_az = string,                     
                     gnodeb_image = string,
                     gnodeb_secgroup_name = string,
                     gnodeb_flavor = string,
                     ue_az = string,
                     ue_image = string,
                     ue_secgroup_name = string,
                     ue_flavor = string,                                     
                     agw_az = string,
                     domain = string})
    default = {
        prefix = "magma"
        bastian_image = "debian_11",
        agw_image = "ubuntu_20.04",
        bastian_flavor = "m1.medium",
        agw_flavor = "m1.medium",
        bastian_az = "zone03",
        agw_az = "zone03",
        public_key = "ssh_keys/id_rsa.pub",
        private_key = "ssh_keys/id_rsa",
        internal_subnet_cidr = "10.20.1.0/24",
        internal_subnet_gw = "10.20.1.1",
        dns_nameservers = [ "10.2.1.55" ],
        domain = "lte.int.",
        external_network = "lb",
        external_subnet = "lb",
        gnodeb_secgroup_name = "gnodeb_sec_group",
        gnodeb_az = "zone03",
        gnodeb_image = "ubuntu_18.04",
        gnodeb_flavor = "m1.medium",
        ue_secgroup_name = "gnodeb_sec_group",
        ue_az = "zone03",
        ue_image = "ubuntu_18.04",
        ue_flavor = "m1.medium",        
        s1_network = "clabext01",
        s1_subnet = "clabext01_ipv4",
        s1_agw_ip = "10.3.0.155"     
    }
}

variable "bootstrapper"{
  description = "The bootstrapper-controller recordset ip"
  default = "0.0.0.0"
}

variable "api"{
  description = "The api recordset ip"
  default = "0.0.0.0"
}

variable "controller"{
  description = "The controller recordset ip"
  default = "0.0.0.0"
}

variable "nms"{
  description = "The controller recordset ip"
  default = "0.0.0.0"
}

variable "fluentd"{
  description = "The fluentd recordset ip"
  default = "0.0.0.0"
}

variable "kibana"{
  description = "The kibana recordset ip"
  default = "0.0.0.0"
}

variable "create_ran" {
  type    = bool
  default = false
}

