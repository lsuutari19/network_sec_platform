provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "docker_image" "nginx" {
  name = "nginx:latest"
}

resource "docker_image" "ubuntu" {
  name = "myubuntu:latest"
}

/* resource "docker_network" "internal_network" {
    name = "internal_network"
    ipam_config {
        gateway = "10.0.0.1"
        subnet = "10.0.0.0/24"
    }
    driver = "macvlan"
} */

resource "null_resource" "create_docker_network" {
  provisioner "local-exec" {
    command     = "docker network inspect mynet2 >/dev/null 2>&1 || echo \"not_exists\""
    interpreter = ["sh", "-c"]
    on_failure  = "continue"
  }
  provisioner "local-exec" {
    command = "sudo docker network create --driver=macvlan --subnet=10.0.0.0/24 -o parent=virbr0 docker_kvm_net"
    when    = "create"
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}

resource "docker_container" "container" {
  image    = docker_image.nginx.image_id
  name     = "foo-nginx"
  must_run = true
  networks_advanced {
    name = "docker_kvm_net"
  }
  publish_all_ports = true
}

resource "docker_container" "container2" {
  depends_on = [libvirt_domain.domain-pfsense, null_resource.create_docker_network]
  image      = docker_image.ubuntu.image_id
  name       = "foo-ubuntu"
  must_run   = true
  networks_advanced {
    name = "docker_kvm_net"
  }
  command = [
    "tail",
    "-f",
    "/dev/null"
  ]

  publish_all_ports = true
}

output "network_data" {
  value = docker_container.container.network_data
}

output "network_data2" {
  value = docker_container.container2.network_data
}
