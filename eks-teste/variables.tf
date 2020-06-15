# ENVIRONMENT 
variable "aws_region" {
  description = "AWS region to launch servers"
  default     = "us-east-1"
}

variable "aws_access_key" {
  default     = 
  description = "User's access key"
}

variable "aws_secret_key" {
  default     = 
  description = "Secret key of this user"
}

variable "cluster-name" {
  default     = "desafio-cluster"
  type        = string
  description = "Define a name for your cluster"
}
