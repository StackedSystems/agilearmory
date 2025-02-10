provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_pool" "k3s_pool" {
  name = "k3s_dev"
  type = "dir"
  path = "/var/lib/libvirt/images/k3s_dev"
}

resource "libvirt_volume" "ubuntu_image" {
  name   = "ubuntu-22.04.qcow2"
  pool   = libvirt_pool.k3s_pool.name
  source = "/var/lib/libvirt/images/ubuntu-22.04.qcow2"
  format = "qcow2"
}

resource "libvirt_domain" "k3s_node" {
  count  = 3
  name   = "k3s-dev-${count.index}"
  memory = 2048
  vcpu   = 2

  disk {
    volume_id = libvirt_volume.ubuntu_image.id
  }

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }
}

output "dev_ips" {
  value = libvirt_domain.k3s_node.*.network_interface[0].addresses
}
