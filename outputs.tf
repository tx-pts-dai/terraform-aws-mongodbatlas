output "peering_id" {
  value       = var.create_vpc_peering == true ? mongodbatlas_network_peering.peering[0].id : null
  description = "Network peering"
}

output "project_id" {
  value       = mongodbatlas_project.project.id
  description = "Mongodb project id"
}

output "region_name" {
  value       = upper(replace(var.aws_region, "-", "_"))
  description = "Mongodb region name"
}
