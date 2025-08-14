variable "project_name" {
  type    = string
  default = "eks-voting-app"
}

variable "region" {
  type    = string
  default = "eu-west-2" # London
}

variable "azs" {
  type    = list(string)
  default = ["eu-west-2a", "eu-west-2b"]
}

variable "node_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "desired_size" {
  type    = number
  default = 2
}
