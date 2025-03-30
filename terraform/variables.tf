variable "cluster_name" {
  default = "prefectCluster"
}

variable "region" {
  default = "eu-central-1"
}

variable "logs_group" {
  default = "/ecs/prefect-proj"
}

variable "prefect_ecr_repository_url" {
  default = "235494809920.dkr.ecr.eu-central-1.amazonaws.com/prefect-server-yarin:latest"
}