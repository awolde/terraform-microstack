terraform {
  required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.49.0"
    }
  }
}

variable "password" {}
provider "openstack" {
  user_name   = "admin"
  tenant_name = "admin"
  password    = var.password
  auth_url    = "https://192.168.1.15:5000/v3/"
  region      = "microstack"
  insecure    = true
}

variable "workers" {
  default = "4"
}

data "template_file" "worker_startup" {
  count    = var.workers
  template = file("${path.module}/worker.yaml")
  vars = {
    master_ip = "192.168.100.191"
    hostname  = "worker-node-${count.index}"
  }
}

variable "image_id" {
  default = "94267a80-6928-4bf7-8677-3c7c32086022"
}

resource "openstack_compute_instance_v2" "worker" {
  count           = var.workers
  name            = "vm_${count.index}"
  image_id        = var.image_id
  key_pair        = "amans"
  security_groups = ["default"]
  flavor_id       = 2
  metadata = {
    purpose = "test"
  }
  network {
    name = openstack_networking_network_v2.internal.name
  }
  power_state = "active"
  user_data   = base64encode(data.template_file.worker_startup[count.index].rendered)
}

resource "openstack_networking_floatingip_v2" "fip_worker" {
  count = var.workers
  pool  = openstack_networking_network_v2.network_ext.name
}

resource "openstack_compute_floatingip_associate_v2" "fip_worker" {
  count       = var.workers
  floating_ip = openstack_networking_floatingip_v2.fip_worker[count.index].address
  instance_id = openstack_compute_instance_v2.worker[count.index].id
}


resource "openstack_compute_instance_v2" "vm2" {
  name            = "vm2"
  image_id        = var.image_id
  key_pair        = "amans"
  security_groups = ["default"]
  flavor_id       = 3
  metadata = {
    purpose = "test"
  }
  network {
    name = openstack_networking_network_v2.internal.name
  }
  user_data = base64encode(file("${path.module}/master.yaml"))
}

resource "openstack_compute_floatingip_associate_v2" "fip_2" {
  floating_ip = openstack_networking_floatingip_v2.fip_2.address
  instance_id = openstack_compute_instance_v2.vm2.id
}

resource "openstack_networking_network_v2" "internal" {
  name           = "local"
  admin_state_up = "true"
  segments {
    network_type = "local"
  }
}

resource "openstack_networking_subnet_v2" "internal" {
  name            = "int-subnet"
  network_id      = openstack_networking_network_v2.internal.id
  cidr            = "192.168.100.0/24"
  ip_version      = 4
  gateway_ip      = "192.168.100.1"
  enable_dhcp     = true
  dns_nameservers = ["192.168.1.1"]
}

resource "openstack_networking_network_v2" "network_ext" {
  name           = "ext"
  admin_state_up = "true"
  external       = true
  segments {
    physical_network = "physnet1"
    network_type     = "flat"
  }
}

resource "openstack_networking_subnet_v2" "external" {
  name       = "ext-subnet"
  network_id = openstack_networking_network_v2.network_ext.id
  cidr       = "192.168.1.0/24"
  ip_version = 4
  allocation_pool {
    end   = "192.168.1.40"
    start = "192.168.1.20"
  }
  dns_nameservers = ["192.168.1.1"]
  gateway_ip      = "192.168.1.1"

}

resource "openstack_networking_router_v2" "router_1" {
  name                = "ext-router"
  admin_state_up      = "true"
  enable_snat         = true
  external_network_id = openstack_networking_network_v2.network_ext.id
}

resource "openstack_networking_router_interface_v2" "internal" {
  router_id = openstack_networking_router_v2.router_1.id
  subnet_id = openstack_networking_subnet_v2.internal.id
}

resource "openstack_networking_floatingip_v2" "fip_2" {
  pool = openstack_networking_network_v2.network_ext.name
}

output "workers" {
  value = openstack_compute_floatingip_associate_v2.fip_worker.*.floating_ip
}