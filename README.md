## Openstack Step by Step

- Get Ubuntu 20 running, with Internet connection.
- Check disk space, memory and cpu
```bash
$ df -h /
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda5       219G   15G  193G   8% /

$ free -g
              total        used        free      shared  buff/cache   available
Mem:             13           0           9           0           4          12
Swap:             1           0           1

$  lscpu
Architecture:                    x86_64
CPU op-mode(s):                  32-bit, 64-bit
Byte Order:                      Little Endian
Address sizes:                   36 bits physical, 48 bits virtual
CPU(s):                          8
On-line CPU(s) list:             0-7
...
```
- Install microstack
```bash
$ sudo snap install microstack --edge
```
- Initialize microstack --> takes 20min or so
```bash
$ sudo microstack init --auto --control
```
- Check to see if new services are listening on ports
```bash
$ sudo netstat -tlpn
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
tcp        0      0 0.0.0.0:4369            0.0.0.0:*               LISTEN      19257/epmd
tcp        0      0 127.0.0.1:631           0.0.0.0:*               LISTEN      955/cupsd
tcp        0      0 0.0.0.0:5000            0.0.0.0:*               LISTEN      29484/nginx: master
tcp        0      0 192.168.1.111:5900      0.0.0.0:*               LISTEN      6667/qemu-system-x8
tcp        0      0 0.0.0.0:6082            0.0.0.0:*               LISTEN      26720/python3
tcp        0      0 0.0.0.0:6642            0.0.0.0:*               LISTEN      18015/ovsdb-server
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      1217/sshd: /usr/sbi
tcp        0      0 0.0.0.0:16509           0.0.0.0:*               LISTEN      30698/libvirtd
tcp        0      0 0.0.0.0:443             0.0.0.0:*               LISTEN      29484/nginx: master
tcp        0      0 0.0.0.0:8764            0.0.0.0:*               LISTEN      24548/python3
...
```
- Get the admin password:
```bash
$ sudo snap get microstack config.credentials.keystone-password
```
- Launch a test vm inside openstack.
```bash
$ microstack launch cirros --name test
```
- Login to admin GUI, use username admin and password you got from above.  Explore the dashboard. Create a new vm.
`https://ip-address-of-your-ubunutu`

### Setup terraform module
Now that we can create vms using the CLI and gui, let's automate the creation of infrastructure with Terraform.
Terraform can run on the same Ubuntu machine your provisioned or from your laptop workstation, it just needs to be able to talk to the
Openstack Ip address.

- Create a new directory - `terraform-openstack`
- Create a new file inside this directory - `main.tf`
- In `main.tf` use the following provider block to connect to your openstack cluster:
```hcl
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
    password    = "the-password-you-got-from-step-above"
    auth_url    = "https://192.168.1.111:5000/v3/"
    region      = "microstack"
    insecure    = true
}
```
- Add a vm creation block in the same `main.tf` file:
```hcl
resource "openstack_compute_instance_v2" "basic" {
  name            = "new_vm"
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
}
```
- Initialize your terraform providers: `$ terraform init`
- See what terraform is going to provision by running a plan: `$ terraform plan`
- Provision the vm: `$ terraform apply`
- Check on the GUI if the vm is created.
- Lets create three vms with a simple additional code:
```hcl
resource "openstack_compute_instance_v2" "basic" {
  count           = 3
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
}
```
- Cleanup all the vms we created: `$ terraform destroy`