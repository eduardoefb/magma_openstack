variable environment {
    type =  object({
                    prefix = string, 
                     public_key = string, 
                     image = string, 
                     s1_network = string,
                     s1_subnet = string,
                     internal_subnet_cidr = string,
                     external_network = string,
                     internal_subnet_gw = string,
                     dns_nameservers = list(string),
                     external_subnet = string,
                     bastian_flavor = string,
                     bastian_az = string,
                     domain = string})
    default = {
        prefix = "magma"
        image = "debian_11",
        bastian_flavor = "m1.medium",
        bastian_az = "zone03",
        public_key = "ssh_keys/id_rsa.pub",
        private_key = "ssh_keys/id_rsa",
        internal_subnet_cidr = "10.20.1.0/24",
        internal_subnet_gw = "10.20.1.1",
        dns_nameservers = [ "10.2.1.55" ],
        domain = "lte.int.",
        external_network = "lb",
        external_subnet = "lb",
        s1_network = "kubespray",
        s1_subnet = "kubespray"        
    }
}
