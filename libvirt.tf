provider "libvirt" {
  uri = "qemu:///system"
}



#provider "libvirt" {
#  alias = "server2"
#  uri   = "qemu+ssh://root@192.168.100.10/system"
#}

resource "libvirt_volume" "centos7-qcow2" {
  name = "${var.vm_machines[count.index]}.qcow2"
  pool = "default"
  #source = "https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2"
  source = "../CentOS-7-x86_64-GenericCloud.qcow2"
  format = "qcow2"
  count = length(var.vm_machines)
}

data "template_file" "user_data" {
  template = file("${path.module}/cloud_init.cfg")
}

# Use CloudInit to add the instance
resource "libvirt_cloudinit_disk" "commoninit" {
  name = "commoninit-${count.index}.iso"
  user_data = data.template_file.user_data.rendered
  
  count = length(var.vm_machines)
}

#define variable for multiple machines
variable "vm_machines" {
  description = "Create machines with these names"
  type = list(string)
  default = ["master01", "worker01"]
}

# Define KVM domain to create
resource "libvirt_domain" "test" {
  count = length(var.vm_machines)
  name   = var.vm_machines[count.index]
  memory = "1024"
  vcpu   = 1

  network_interface {
    network_name = "default"
  }

  disk {
    volume_id = element(libvirt_volume.centos7-qcow2.*.id,count.index)
  }

  cloudinit = libvirt_cloudinit_disk.commoninit[count.index].id

  console {
    type = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = true
  }
}

# Output Server IP
#output "ip" {
#  value = "${libvirt_domain.db1.network_interface.0.addresses.0}"
#}
