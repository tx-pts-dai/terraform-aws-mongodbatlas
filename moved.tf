moved {
  from = mongodbatlas_project.project
  to   = mongodbatlas_project.project[0]
}

moved {
  from = mongodbatlas_project_ip_access_list.public_ips
  to   = mongodbatlas_project_ip_access_list.ips
}
