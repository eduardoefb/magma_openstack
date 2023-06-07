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

data "openstack_dns_zone_v2" "zone"{
  name        = "${var.zone}."
  
}

resource "openstack_dns_recordset_v2" "bootstrapper-controller" {
  zone_id     = data.openstack_dns_zone_v2.zone.id
  name        = "bootstrapper-controller.${var.zone}."
  description = "bootstrapper"
  ttl         = 3000
  type        = "A"
  records     = [ "${var.bootstrapper}" ]

}

resource "openstack_dns_recordset_v2" "api" {
  zone_id     = data.openstack_dns_zone_v2.zone.id
  name        = "api.${var.zone}."
  description = "api"
  ttl         = 3000
  type        = "A"
  records     = [ "${var.api}" ]

}

resource "openstack_dns_recordset_v2" "controller" {
  zone_id     = data.openstack_dns_zone_v2.zone.id
  name        = "controller.${var.zone}."
  description = "controller"
  ttl         = 3000
  type        = "A"
  records     = [ "${var.controller}" ]


}

resource "openstack_dns_recordset_v2" "nms" {
  zone_id     = data.openstack_dns_zone_v2.zone.id
  name        = "*.nms.${var.zone}."
  description = "nms"
  ttl         = 3000
  type        = "A"
  records     = [ "${var.nms}" ]

}

resource "openstack_dns_recordset_v2" "nms_host" {
  zone_id     = data.openstack_dns_zone_v2.zone.id
  name        = "host.nms.${var.zone}."
  description = "nms"
  ttl         = 3000
  type        = "A"
  records     = [ "${var.nms}" ]

}

resource "openstack_dns_recordset_v2" "nms_custom" {
  zone_id     = data.openstack_dns_zone_v2.zone.id
  name        = "custom.nms.${var.zone}."
  description = "nms"
  ttl         = 3000
  type        = "A"
  records     = [ "${var.nms}" ]

}

resource "openstack_dns_recordset_v2" "fluentd" {
  zone_id     = data.openstack_dns_zone_v2.zone.id
  name        = "fluentd.${var.zone}."
  description = "fluentd"
  ttl         = 3000
  type        = "A"
  records     = [ "${var.fluentd}" ]

}

resource "openstack_dns_recordset_v2" "kibana" {
  zone_id     = data.openstack_dns_zone_v2.zone.id
  name        = "kibana.${var.zone}."
  description = "kibana"
  ttl         = 3000
  type        = "A"
  records     = [ "${var.kibana}" ]

}

#################Variables##########################################

variable "zone" {
  description = "The name of the DNS zone"
}

variable "bootstrapper"{
  description = "The bootstrapper-controller recordset ip"
}

variable "api"{
  description = "The api recordset ip"
}

variable "controller"{
  description = "The controller recordset ip"
}

variable "nms"{
  description = "The controller recordset ip"
}

variable "fluentd"{
  description = "The fluentd recordset ip"
}

variable "kibana"{
  description = "The kibana recordset ip"
}


