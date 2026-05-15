variable "aws_region" {
  type    = string
  default = "eu-west-3"
}

variable "project" {
  type    = string
  default = "tp5-cloudsec"
}

variable "name_suffix" {
  type        = string
}

variable "db_host" {
  type    = string
  default = "db.example.local"
}

variable "api_token" {
  type        = string
  sensitive   = true
}

variable "log_retention_days" {
  type    = number
  default = 7
}
