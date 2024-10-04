data "aws_caller_identity" "current" {}

data "aws_vpc" "this" {
  id = var.vpc_id
}

locals {
  project_id = var.create_project ? mongodbatlas_project.project[0].id : data.mongodbatlas_project.this[0].id
}

data "mongodbatlas_project" "this" {
  count = !var.create_project ? 1 : 0

  name = var.project_name
}

resource "mongodbatlas_project" "project" {
  count = var.create_project ? 1 : 0

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
  count = var.create_vpc_peering ? 1 : 0

  project_id = local.project_id
  cidr_block = data.aws_vpc.this.cidr_block
}

resource "mongodbatlas_project_ip_access_list" "additional_cidr" {
  count = var.override_peering_cidr != null ? 1 : 0

  project_id = local.project_id
  cidr_block = var.override_peering_cidr
}

resource "mongodbatlas_project_ip_access_list" "public_ips" {
  for_each = toset(var.create_vpc_peering && var.create_privatelink ? [] : var.vpc_public_ips)

  project_id = local.project_id
  ip_address = each.value
}

resource "mongodbatlas_network_container" "container" {
  count = var.create_vpc_peering ? 1 : 0

  project_id       = local.project_id
  atlas_cidr_block = var.atlas_cidr_block
  provider_name    = var.provider_name
  region_name      = upper(replace(var.aws_region, "-", "_"))
}

resource "mongodbatlas_network_peering" "peering" {
  count = var.create_vpc_peering ? 1 : 0

  accepter_region_name   = var.aws_region
  project_id             = mongodbatlas_network_container.container[0].project_id
  container_id           = mongodbatlas_network_container.container[0].container_id
  provider_name          = var.provider_name
  route_table_cidr_block = var.override_peering_cidr != null ? var.override_peering_cidr : data.aws_vpc.this.cidr_block
  vpc_id                 = var.vpc_id
  aws_account_id         = data.aws_caller_identity.current.account_id
}

resource "aws_vpc_peering_connection_accepter" "atlas" {
  count = var.create_vpc_peering ? 1 : 0

  vpc_peering_connection_id = mongodbatlas_network_peering.peering[0].connection_id
  auto_accept               = true
}

data "aws_route_table" "private_routing_tables" {
  for_each = toset(var.private_subnets)

  subnet_id = each.value
}

resource "aws_route" "atlas_route" {
  for_each = toset([for o in data.aws_route_table.private_routing_tables : o.route_table_id if var.create_vpc_peering == true])

  route_table_id            = each.value
  destination_cidr_block    = var.atlas_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.atlas[0].id
}

resource "aws_vpc_endpoint" "this" {
  count = var.create_privatelink ? 1 : 0

  vpc_id             = data.aws_vpc.this.id
  service_name       = mongodbatlas_privatelink_endpoint.this[0].endpoint_service_name
  vpc_endpoint_type  = "Interface"
  subnet_ids         = var.private_subnets
  security_group_ids = [aws_security_group.this[0].id]
}

resource "mongodbatlas_privatelink_endpoint" "this" {
  count = var.create_privatelink ? 1 : 0

  project_id    = local.project_id
  provider_name = var.provider_name
  region        = var.aws_region
}

resource "mongodbatlas_privatelink_endpoint_service" "this" {
  count = var.create_privatelink ? 1 : 0

  project_id          = mongodbatlas_privatelink_endpoint.this[0].project_id
  private_link_id     = mongodbatlas_privatelink_endpoint.this[0].id
  endpoint_service_id = aws_vpc_endpoint.this[0].id
  provider_name       = "AWS"
}

resource "aws_security_group" "this" {
  count = var.create_privatelink ? 1 : 0

  name_prefix = "mongodbatlas-privatelink"
  description = "Security group for MongoDB Atlas Private Link"
  vpc_id      = data.aws_vpc.this.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "tcp"
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
