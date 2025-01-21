terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = "npipe:////./pipe/docker_engine"
}

resource "docker_network" "app_network" {
  name = "app_network"
  driver = "bridge"
}

resource "docker_volume" "db_data" {
  name = "db_data"
}

resource "docker_image" "app_image" {
  name         = "moshelederman/project-stars"
  keep_locally = false
}

resource "docker_container" "app" {
  name  = "project-stars"
  image = docker_image.app_image.id

  ports {
    internal = 5000
    external = 5000
  }

  networks_advanced {
    name = docker_network.app_network.name
  }

  depends_on = [docker_container.db]
}

resource "docker_image" "mysql_image" {
  name = "mysql:8.0"
}

resource "docker_container" "db" {
  name  = "docker-gif-db"
  image = docker_image.mysql_image.id

  env = [
    "MYSQL_ROOT_PASSWORD=${var.mysql_root_password}",
    "MYSQL_DATABASE=${var.mysql_database}",
    "MYSQL_USER=${var.mysql_user}",
    "MYSQL_PASSWORD=${var.mysql_password}"
  ]

  ports {
    internal = 3306
    external = 3308
  }

  volumes {
    container_path = "/var/lib/mysql"
    host_path      = "/c/docker_volumes/db_data"
  }

  networks_advanced {
    name = docker_network.app_network.name
  }

  healthcheck {
    test     = ["CMD", "mysqladmin", "ping", "-h", "127.0.0.1", "-u", var.mysql_user, "-p${var.mysql_password}"]
    interval = "10s"
    timeout  = "5s"
    retries  = 3
  }
}
