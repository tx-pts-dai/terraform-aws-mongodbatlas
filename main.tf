data "aws_caller_identity" "current" {}

data "aws_vpc" "this" {
  count = var.create_vpc_peering || var.create_privatelink ? 1 : 0

  id = var.vpc_id
}

locals {
  project_id = var.create_project ? mongodbatlas_project.project[0].id : data.mongodbatlas_project.this[0].id
  vpc_id     = var.create_vpc_peering || var.create_privatelink ? data.aws_vpc.this[0].id : null
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
  cidr_block = data.aws_vpc.this[0].cidr_block
}

resource "mongodbatlas_project_ip_access_list" "additional_cidr" {
  count = var.override_peering_cidr != null ? 1 : 0

  project_id = local.project_id
  cidr_block = var.override_peering_cidr
}

# TODO: remove on next MAJOR release
resource "mongodbatlas_project_ip_access_list" "public_ips" {
  count = var.create_vpc_peering || var.create_privatelink ? 0 : length(var.vpc_public_ips)

  project_id = local.project_id
  ip_address = var.vpc_public_ips[count.index]
}

resource "mongodbatlas_project_ip_access_list" "ips" {
  for_each = { for k, v in var.ip_access_list : v.ip => v }

  project_id = local.project_id

  ip_address = can(regex(".*/", each.value.ip)) ? null : each.value.ip
  cidr_block = can(regex(".*/", each.value.ip)) ? each.value.ip : null

  comment = each.value.comment

  # TODO: remove on next MAJOR release
  # Helps to support the migration to the new variable
  # ensuring that conflicts do not happen
  depends_on = [
    mongodbatlas_project_ip_access_list.public_ips
  ]
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
  route_table_cidr_block = var.override_peering_cidr != null ? var.override_peering_cidr : data.aws_vpc.this[0].cidr_block
  vpc_id                 = local.vpc_id
  aws_account_id         = data.aws_caller_identity.current.account_id
}

resource "aws_vpc_peering_connection_accepter" "atlas" {
  count = var.create_vpc_peering ? 1 : 0

  vpc_peering_connection_id = mongodbatlas_network_peering.peering[0].connection_id
  auto_accept               = true
}

data "aws_route_tables" "private_routing_tables" {
  count = var.create_vpc_peering ? 1 : 0

  vpc_id = local.vpc_id

  filter {
    name   = "association.subnet-id"
    values = var.private_subnets
  }
}

resource "aws_route" "atlas_route" {
  count = var.create_vpc_peering ? length(data.aws_route_tables.private_routing_tables[0].ids) : 0

  route_table_id            = data.aws_route_tables.private_routing_tables[0].ids[count.index]
  destination_cidr_block    = var.atlas_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.atlas[0].id
}

resource "aws_vpc_endpoint" "this" {
  count = var.create_privatelink ? 1 : 0

  vpc_id             = local.vpc_id
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
  private_link_id     = mongodbatlas_privatelink_endpoint.this[0].private_link_id
  endpoint_service_id = aws_vpc_endpoint.this[0].id
  provider_name       = "AWS"
}

resource "aws_security_group" "this" {
  count = var.create_privatelink ? 1 : 0

  name_prefix = "mongodbatlas-privatelink"
  description = "Security group for MongoDB Atlas Private Link"
  vpc_id      = local.vpc_id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
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
