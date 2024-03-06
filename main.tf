provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "pfsense-qcow2" {
  name   = "pfsense-volume.qcow2"
  pool   = var.pool_dir
  source = var.pfsense_img_url
  format = "qcow2"
}

data "template_file" "user_data" {
  template = file("${path.module}/config/cloud_init.yml")
}

data "template_file" "network_config" {
  template = file("${path.module}/config/network_config.yml")
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name      = "pfsense_commoninit.iso"
  user_data = data.template_file.user_data.rendered
  pool      = var.pool_dir
}

# connects pfSense to the external network
resource "libvirt_network" "default_network" {
  name      = "external_network"
  mode      = "nat"
  addresses = ["198.168.122.2/24"]
  dns {
    enabled = true
  }
  dhcp {
    enabled = true
  }
}

resource "libvirt_network" "vmbr0-net" {
  name = "internal_network"
  mode = "none"
}

resource "libvirt_network" "vmbr1-net" {
  name = "demilitarized_zone"
  mode = "none"
}

resource "libvirt_domain" "domain-pfsense" {
  name    = "pfsense-domain"
  memory  = "2048"
  vcpu    = 2
  machine = "q35"

  xml {
    xslt = file("${path.module}/config/cdrom-model.xsl")
  }
  cloudinit = libvirt_cloudinit_disk.commoninit.id
  network_interface {
    network_name = libvirt_network.default_network.name
  }
  network_interface {
    network_name = libvirt_network.vmbr0-net.name
  }
  network_interface {
    network_name = libvirt_network.vmbr1-net.name
  }
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }
  disk {
    volume_id = libvirt_volume.pfsense-qcow2.id
  }
  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}
