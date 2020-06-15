variable "aws_region" {
  description = "AWS region to launch servers"
  default = "us-east-1"
}
variable "aws_access_key" {
  description = ""
}
variable "aws_secret_key" {
  description = ""
}

variable "namespace_name" {
  default = "desafio-ns"
  type = "string"
}

variable "nginx_pod_name" {
  default = "desafio-pod"
  type = "string"
}

variable "nginx_pod_image" {
  default = "nginx:latest"
  type = "string"
}
