resource "libvirt_volume" "ubuntu-qcow2" {
  name   = "ubuntu-volume.qcow2"
  pool   = var.pool_dir
  source = var.ubuntu_img_url
  format = "qcow2"
}

data "template_file" "ubuntu-user_data" {
  template = file("${path.module}/config/ubuntu_cloud_init.yml")
}

data "template_file" "ubuntu-network_config" {
  template = file("${path.module}/config/network_config.yml")
}

resource "libvirt_cloudinit_disk" "ubuntu-commoninit" {
  name      = "ubuntu-commoninit.iso"
  user_data = data.template_file.ubuntu-user_data.rendered
  pool      = var.pool_dir
}

resource "libvirt_domain" "ubuntu-domain" {
  name    = "ubuntu-domain"
  memory  = "2048"
  vcpu    = 2
  machine = "q35"

  xml {
    xslt = file("${path.module}/config/cdrom-model.xsl")
  }
  cloudinit = libvirt_cloudinit_disk.ubuntu-commoninit.id
  network_interface {
    network_name = libvirt_network.vmbr0-net.name
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
    volume_id = libvirt_volume.ubuntu-qcow2.id
  }
  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}
