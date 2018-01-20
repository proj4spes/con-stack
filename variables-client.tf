
variable "key_name" {
  description = "The name of an EC2 Key Pair that can be used to SSH to the Client Instances in this cluster. Set to an empty string to not associate a Key Pair."
  default     = "asd"
}

variable "name" {
  description = "The name of stack."
  default     = "stack"
}

variable "environment" {
  description = "The name of environment of stack ie. prod/stage/test."
  default     = "test"
}
