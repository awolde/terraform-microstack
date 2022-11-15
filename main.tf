terraform {
  required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.49.0"
    }
  }
}

provider "openstack" {
  user_name   = "admin"
  tenant_name = "admin"
  password    = "hUJzmG8VTGAZJOO1SQ8RmTsEA8K7wcEl"
  auth_url    = "https://192.168.1.111:5000/v3/"
  region      = "microstack"
  insecure    = true
  //  domain_name = "default"
  //  tenant_id = "admin"
  //  application_credential_id = "8a21b03dbbd2485db34d8fecc3cf016b"
  //  application_credential_secret = "b2aJiiLhYw5IZVUA0qWkN5WzY7ZxYLN4tENWm_RqmyEy0E0y_y1cQz3q8NOsZEOA8S2l0r-k9ZfRwIsQUk6vcQ"
  //  application_credential_name = "tfo"
}

resource "openstack_compute_instance_v2" "basic" {
  count = 3
  name            = "new_vm_${count.index}"
  image_id        = "b7a26e18-3d0d-4f9d-b4bb-16fa1566b40f"
  key_pair        = "microstack"
  security_groups = ["default"]
  flavor_id = 1
  metadata = {
    purpose = "test"
  }
  network {
    name = "test"
  }
  power_state = "shutoff"
}