provider "docker" {
  host = "unix:///var/run/docker.sock"
}

/* resource "docker_network" "internal_network" {
    name = "internal_network"
    ipam_config {
        gateway = "10.0.0.1"
        subnet = "10.0.0.0/24"
    }
    driver = "macvlan"
} */

resource "null_resource" "destroy_docker_container" {
  provisioner "local-exec" {
    command = "docker rm -f foo-nginx foo-ubuntu"
    on_failure = continue
  }
}

resource "null_resource" "build_docker_image" {
  provisioner "local-exec" {
    command = "docker build -t myubuntu ./ubuntu/"
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}

resource "null_resource" "create_docker_network" {
  provisioner "local-exec" {
    command     = "docker network rm -f docker_kvm_net || echo \"network doesnt exist yet\""
    interpreter = ["sh", "-c"]
    on_failure  = continue
  }
  provisioner "local-exec" {
    command = "docker network create --driver=macvlan --subnet=10.0.0.0/24 -o parent=virbr0 docker_kvm_net"
    when    = create
    on_failure = continue
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}

resource "docker_image" "nginx" {
  name = "nginx:latest"
}

resource "docker_image" "ubuntu" {
  name = "myubuntu:latest"
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
  # depends_on = [libvirt_domain.domain-pfsense, null_resource.create_docker_network, null_resource.build_docker_image]
  image      =  "myubuntu"
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

output "nginx_network_settings" {
  value = docker_container.container.network_data
}

output "ubuntu_network_settings" {
  value = docker_container.container2.network_data
}
