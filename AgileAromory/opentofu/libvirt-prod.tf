provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_pool" "k3s_pool" {
  name = "k3s_prod"
  type = "dir"
  path = "/var/lib/libvirt/images/k3s_prod"
}

resource "libvirt_volume" "rhel_image" {
  name   = "rhel-9.qcow2"
  pool   = libvirt_pool.k3s_pool.name
  source = "/var/lib/libvirt/images/rhel-9.qcow2"
  format = "qcow2"
}

resource "libvirt_domain" "k3s_node" {
  count  = 3
  name   = "k3s-prod-${count.index}"
  memory = 4096
  vcpu   = 4

  disk {
    volume_id = libvirt_volume.rhel_image.id
  }

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  provisioner "remote-exec" {
    inline = [
      "subscription-manager register --username=your_user --password=your_pass",
      "subscription-manager attach --auto"
    ]
  }
}

output "prod_ips" {
  value = libvirt_domain.k3s_node.*.network_interface[0].addresses
}
