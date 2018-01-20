variable "name" {}

variable "namespace" {}

variable "stage" {}

variable "roles" {
  type        = "list"
  description = "Principal IAM roles to provide with access to the ECR"
  default     = []
}

variable "delimiter" {
  type    = "string"
  default = "-"
}

variable "attributes" {
  type    = "list"
  default = []
}

variable "tags" {
  type    = "map"
  default = {}
}

variable max_n_t {
          description     = " max number of tagged image"
          default = 30
}

variable max_age {
          description = "The max age of untagged image"
          default = 60
}

