variable "project_name" {
  default = "api-ha"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "alarm_email" {
  type        = string
  default     = "luisneu@gmail.com"
}

variable "image_ecs" {
  type        = string
  default     = "443370700365.dkr.ecr.us-east-1.amazonaws.com/api-node:1.1"
}
