terraform {
  required_version = ">= 1.6"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

locals {
  common_tags = {
    project     = var.app_name
    environment = var.environment
    managed_by  = "terraform"
  }

  container_name = "${var.app_name}-${var.environment}"
}

data "docker_network" "bridge" {
  name = "bridge"
}

resource "docker_network" "app_network" {
  name = "devops-network"
}

resource "docker_image" "nginx" {
  name         = "nginx:alpine"
  keep_locally = true
}

resource "docker_container" "web" {
  name  = local.container_name
  image = docker_image.nginx.image_id

  ports {
    internal = 80
    external = var.web_port
  }

  networks_advanced {
    name = docker_network.app_network.name
  }

  env = [
    "NGINX_HOST=localhost",
    "NGINX_PORT=80"
  ]

  labels {
    label = "project"
    value = local.common_tags.project
  }

  labels {
    label = "environment"
    value = local.common_tags.environment
  }

  labels {
    label = "managed_by"
    value = local.common_tags.managed_by
  }
}

output "web_url" {
  value       = "http://localhost:${docker_container.web.ports[0].external}"
  description = "URL du serveur web"
}

output "container_id" {
  value = docker_container.web.id
}
