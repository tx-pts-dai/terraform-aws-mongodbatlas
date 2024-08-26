variable "provider_name" {
  type        = string
  description = "Provider name for Atlas Mongodb resources"
}

variable "atlas_cidr_block" {
  default     = "10.8.0.0/21"
  description = " CIDR block for MongoDB resources "
  type        = string
}

variable "aws_region" {
  type        = string
  description = "Region for AWS and for Mongodb resources "
}

variable "vpc_id" {
  type        = string
  description = "VPC of Atlas MongoDB resources "
}

variable "vpc_public_ips" {
  type        = list(string)
  description = "List of public IP addresses of the VPC"
}

variable "mongodb_atlas_org_id" {
  type        = string
  description = "ID of the Organization on Atlas"
}

variable "project_name" {
  type        = string
  description = "Name of the Mongodb project"
}

variable "team_ids" {
  type = list(object({
    team_id   = string
    team_role = list(string)
  }))
  default     = []
  description = "Id of the infra team of the Organization on Atlas"
}

variable "private_subnets" {
  type        = list(any)
  description = "AWS private networks subnets which can connect to the db and which enable HA "
}

variable "create_vpc_peering" {
  type        = bool
  description = "Create a Vpc Peering Connection if set to True for instances that are M10 size or higher"
}

variable "override_peering_cidr" {
  type        = string
  default     = null
  description = "Manually overrides the network peering cidr block"
}
