provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "docker_image" "nginx" {
  name = "nginx:latest"
}

resource "docker_image" "ubuntu" {
    name = "ubuntu:latest"
}

resource "docker_network" "internal_network" {
    name = "internal_network"
    ipam_config {
        ip_range = "10.0.0.248/29"
        gateway = "10.0.0.2"
        subnet = "10.0.0.0/24"
    }
    driver = "macvlan"
}

resource "docker_container" "container" {
  image = docker_image.nginx.image_id
  name  = "foo-nginx"
  must_run = true
  networks_advanced {
    name = "internal_network"
  }
  
  publish_all_ports = true
}

resource "docker_container" "container2" {
  image = docker_image.ubuntu.image_id
  name  = "foo-ubuntu"
  must_run = true
  networks_advanced {
    name = "internal_network"
  }
  command = [
    "tail",
    "-f",
    "/dev/null"
  ]
  
  publish_all_ports = true
} 


output "network_data" {
  value = "${docker_container.container.network_data}"
}

output "ip_addresses" {
  value = "${list(
    lookup(docker_container.container.network_data[0], "ip_address"),
  )}"
}
