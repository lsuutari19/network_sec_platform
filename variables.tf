variable "libvirt_disk_path" {
  description = "path for libvirt pool"
  default     = "/opt/kvm/pool1"
}

variable "pfsense_img_url" {
  description = "pfsense image"
  default     = "images/router_pfsense.qcow2"
}

variable "ubuntu_img_url" {
  description = "ubuntu image"
  default     = "images/linux_server.qcow2"
}

variable "kali_img_url" {
  description = "kali desktop image"
  default     = "images/kali-linux-2023.4-qemu-amd64.qcow2"
}

variable "ssh_username" {
  description = "the ssh user to use"
  default     = "ssh-pfsense"
}

variable "ssh_private_key" {
  description = "the private key to use"
  default     = "~/.ssh/id_rsa"
}

variable "pool_dir" {
  description = "path for vm_volume pool storage"
  default     = "default_pool"
}
