variable "mongodb_atlas_org_id" {
  type        = string
  description = "ID of the Organization on Atlas"
}

variable "provider_name" {
  description = "Provider name for Atlas Mongodb resources"
  type        = string

  default = "AWS"
}

variable "create_project" {
  description = "Create a project on Atlas if set to True"
  type        = bool

  default = true
}

variable "project_name" {
  description = "Name of the Mongodb project"
  type        = string
}

variable "team_ids" {
  description = "Id of the infra team of the Organization on Atlas"
  type = list(object({
    team_id   = string
    team_role = list(string)
  }))

  default = []
}

variable "atlas_cidr_block" {
  description = "CIDR block for MongoDB resources"
  type        = string

  default = "10.8.0.0/21"
}

variable "aws_region" {
  description = "Region for AWS and for Mongodb resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC of Atlas MongoDB resources"
  type        = string

  default = null
}

# TODO: remove on next MAJOR release
variable "vpc_public_ips" {
  description = "(Deprecated, use `ip_access_list` instead)\nList of public IP addresses of the VPC"
  type        = list(string)

  default = []
}

variable "ip_access_list" {
  description = <<EOF
    List of allowed IPs to the project

    ip     : can be either an IP address or CIDR block
    comment: useful information to identify the IP
  EOF
  type = list(object({
    ip      = string
    comment = string
  }))

  default = []
}

variable "private_subnets" {
  description = "AWS private subnet ids which can connect to the db and which enable HA"
  type        = list(string)

  default = []
}

variable "create_vpc_peering" {
  type        = bool
  description = "Create a Vpc Peering Connection if set to True for instances that are M10 size or higher"

  default = false
}

variable "override_peering_cidr" {
  description = "Manually overrides the network peering cidr block"
  type        = string

  default = null
}

variable "create_privatelink" {
  description = "Create a PrivateLink Connection if set to True for instances that are M10 size or higher"
  type        = bool

  default = false
}
