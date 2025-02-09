provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_domain" "k3s_dev" {
  count  = 3
  name   = "k3s-dev-${count.index}"
  memory = 2048
  vcpu   = 2

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }
}
