terraform {
  required_version = ">=1.0.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = ">= 1.0"
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_vpc" "this" {
  id = var.vpc_id
}

resource "mongodbatlas_project" "project" {
  org_id = var.mongodb_atlas_org_id
  name   = var.project_name
  dynamic "teams" {
    for_each = var.team_ids
    content {
      team_id    = teams.value["team_id"]
      role_names = teams.value["team_role"]
    }
  }
}

resource "mongodbatlas_project_ip_access_list" "vpc" {
  count      = var.create_vpc_peering == true ? 1 : 0
  project_id = mongodbatlas_project.project.id
  cidr_block = data.aws_vpc.this.cidr_block
}

resource "mongodbatlas_project_ip_access_list" "additional_cidr" {
  count      = var.override_peering_cidr != null ? 1 : 0
  project_id = mongodbatlas_project.project.id
  cidr_block = var.override_peering_cidr
}

resource "mongodbatlas_project_ip_access_list" "public_ips" {
  for_each   = toset(var.create_vpc_peering == true ? [] : var.vpc_public_ips)
  project_id = mongodbatlas_project.project.id
  ip_address = each.value
}

resource "mongodbatlas_network_container" "container" {
  count            = var.create_vpc_peering == true ? 1 : 0
  project_id       = mongodbatlas_project.project.id
  atlas_cidr_block = var.atlas_cidr_block
  provider_name    = var.provider_name
  region_name      = upper(replace(var.aws_region, "-", "_"))
}

resource "mongodbatlas_network_peering" "peering" {
  count                  = var.create_vpc_peering == true ? 1 : 0
  accepter_region_name   = var.aws_region
  project_id             = mongodbatlas_network_container.container[0].project_id
  container_id           = mongodbatlas_network_container.container[0].container_id
  provider_name          = var.provider_name
  route_table_cidr_block = var.override_peering_cidr != null ? var.override_peering_cidr : data.aws_vpc.this.cidr_block
  vpc_id                 = var.vpc_id
  aws_account_id         = data.aws_caller_identity.current.account_id
}

resource "aws_vpc_peering_connection_accepter" "atlas" {
  count                     = var.create_vpc_peering == true ? 1 : 0
  vpc_peering_connection_id = mongodbatlas_network_peering.peering[0].connection_id
  auto_accept               = true
}

data "aws_route_table" "private_routing_tables" {
  for_each  = toset(var.private_subnets)
  subnet_id = each.value
}

resource "aws_route" "atlas_route" {
  for_each                  = toset([for o in data.aws_route_table.private_routing_tables : o.route_table_id if var.create_vpc_peering == true])
  route_table_id            = each.value
  destination_cidr_block    = var.atlas_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.atlas[0].id
}
