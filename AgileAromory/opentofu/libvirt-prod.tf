provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_domain" "k3s_prod" {
  count  = 3
  name   = "k3s-prod-${count.index}"
  memory = 4096
  vcpu   = 4

  provisioner "remote-exec" {
    inline = [
      "subscription-manager register --username=your_user --password=your_pass",
      "subscription-manager attach --auto"
    ]
  }
}
