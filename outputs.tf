output "peering_id" {
  value       = var.create_vpc_peering == true ? mongodbatlas_network_peering.peering[0].id : null
  description = "Network peering"
}

output "project_id" {
  value       = local.project_id
  description = "Mongodb project id"
}

output "region_name" {
  value       = upper(replace(var.aws_region, "-", "_"))
  description = "Mongodb region name"
}

output "private_link_endpoint" {
  value       = var.create_privatelink == true ? aws_vpc_endpoint.this[0] : null
  description = "Private link"
}
