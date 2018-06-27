# -- Access keys 
# These must be stored in a private file and not stored in a file versioning repository.
variable "access_key" {}

variable "secret_key" {}

# -- Region
# This will deploy the infrastructure to a given region code. 

variable "region" {
  default = "us-east-2"
}

# -- VPC variables
# These variablse need defining in terraform.tfvars before deployment.

variable "public_key_path" {}
variable "keyname" {}
variable "vpc_name" {}
variable "vpc_cidr_block" {}
variable "public_subnet_cidr_block" {}

# cidrs will be a list that can be refferred to as key-pair.
variable "cidrs" {
  type = "map"
}
