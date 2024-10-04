# MongoDB Atlas made easy

Easy way to setup an Atlas MongoDB project with its network peering with an AWS account.

## Core concepts

This Module covers the use case of managing:

- a MongoDB Atlas project
- it's network peering with an AWS account

## Usage

```HCL

locals {
  # Mongdb Atlas IDs can be found by checking the URL when navigating
  # the web console https://cloud.mongodb.com.
  # ORG_ID = part after `/orgs/` on the home page
  # TEAM_ID  = part after the `/teams/` when checking Team's details
  mongodb_atlas_org_id = "24_hexchar"

  # List of AWS private subnet IDs to peer to
  private_subnets = ["subnet-17_hexchar", "subnet-17_hexchar", "..."]

  # Name you wantn to have for your Atlas MongoDB Project
  project_name = "Module Sandbox"

  # Teams you want to allow using the VPC
  # See TEAM_ID above
  teams_ids = [
    { team_id = TEAM_ID1, team_role = ["GROUP_OWNER"] },
    { team_id = TEAM_ID2, team_role = ["GROUP_DATA_ACCESS_READ_ONLY"] },
  ]

  # AWS VPC ID
  vpc_idf = "vpc-17_hexchar"

  # List of AWS NAT Gateway public IPs
  vpc_public_ips = ["1.1.1.1", "1.2.2.1", "..."]
}

module "mongodb" {
  source  = "tx-pts-dai/mongodbatlas/aws"
  version = "v0.0.1"

  atlas_cidr_block      = "10.8.0.0/21"
  aws_region            = "eu-central-1"
  create_vpc_peering    = true
  mongodb_atlas_org_id  = local.mongodb_atlas_org_id
  override_peering_cidr = null
  private_subnets       = local.private_subnets
  project_name          = local.project_name
  provider_name         = "AWS"
  team_ids              = local.teams_ids
  vpc_id                = local.vpc_id
  vpc_public_ips        = local.vpc_public_ips
}
```

Will manage the following resources:

- An MongoDB Atlas Project
- MongoDB Atlas IP Access Lists
- MongoDB Atlas Network Container
- MongoDB Atlas Network Peering
- AWS VPC Peering Accepter
- AWS Route

## Contributing

< issues and contribution guidelines for public modules >

### Pre-Commit

Installation: [install pre-commit](https://pre-commit.com/) and execute `pre-commit install`. This will generate pre-commit hooks according to the config in `.pre-commit-config.yaml`

Before submitting a PR be sure to have used the pre-commit hooks or run: `pre-commit run -a`

The `pre-commit` command will run:

- Terraform fmt
- Terraform validate
- Terraform docs
- Terraform validate with tflint
- check for merge conflicts
- fix end of files

as described in the `.pre-commit-config.yaml` file

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |
| <a name="requirement_mongodbatlas"></a> [mongodbatlas](#requirement\_mongodbatlas) | >= 1.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0 |
| <a name="provider_mongodbatlas"></a> [mongodbatlas](#provider\_mongodbatlas) | >= 1.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_route.atlas_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_endpoint.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_peering_connection_accepter.atlas](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_peering_connection_accepter) | resource |
| [mongodbatlas_network_container.container](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/network_container) | resource |
| [mongodbatlas_network_peering.peering](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/network_peering) | resource |
| [mongodbatlas_privatelink_endpoint.this](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/privatelink_endpoint) | resource |
| [mongodbatlas_privatelink_endpoint_service.this](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/privatelink_endpoint_service) | resource |
| [mongodbatlas_project.project](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/project) | resource |
| [mongodbatlas_project_ip_access_list.additional_cidr](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/project_ip_access_list) | resource |
| [mongodbatlas_project_ip_access_list.public_ips](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/project_ip_access_list) | resource |
| [mongodbatlas_project_ip_access_list.vpc](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/project_ip_access_list) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_route_table.private_routing_tables](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route_table) | data source |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |
| [mongodbatlas_project.this](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/data-sources/project) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_atlas_cidr_block"></a> [atlas\_cidr\_block](#input\_atlas\_cidr\_block) | CIDR block for MongoDB resources | `string` | `"10.8.0.0/21"` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | Region for AWS and for Mongodb resources | `string` | n/a | yes |
| <a name="input_create_privatelink"></a> [create\_privatelink](#input\_create\_privatelink) | Create a PrivateLink Connection if set to True for instances that are M10 size or higher | `bool` | `false` | no |
| <a name="input_create_project"></a> [create\_project](#input\_create\_project) | Create a project on Atlas if set to True | `bool` | `true` | no |
| <a name="input_create_vpc_peering"></a> [create\_vpc\_peering](#input\_create\_vpc\_peering) | Create a Vpc Peering Connection if set to True for instances that are M10 size or higher | `bool` | n/a | yes |
| <a name="input_mongodb_atlas_org_id"></a> [mongodb\_atlas\_org\_id](#input\_mongodb\_atlas\_org\_id) | ID of the Organization on Atlas | `string` | n/a | yes |
| <a name="input_override_peering_cidr"></a> [override\_peering\_cidr](#input\_override\_peering\_cidr) | Manually overrides the network peering cidr block | `string` | `null` | no |
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | AWS private subnet ids which can connect to the db and which enable HA | `list(string)` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the Mongodb project | `string` | n/a | yes |
| <a name="input_provider_name"></a> [provider\_name](#input\_provider\_name) | Provider name for Atlas Mongodb resources | `string` | `"AWS"` | no |
| <a name="input_team_ids"></a> [team\_ids](#input\_team\_ids) | Id of the infra team of the Organization on Atlas | <pre>list(object({<br>    team_id   = string<br>    team_role = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC of Atlas MongoDB resources | `string` | n/a | yes |
| <a name="input_vpc_public_ips"></a> [vpc\_public\_ips](#input\_vpc\_public\_ips) | List of public IP addresses of the VPC | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_peering_id"></a> [peering\_id](#output\_peering\_id) | Network peering |
| <a name="output_private_link_endpoint"></a> [private\_link\_endpoint](#output\_private\_link\_endpoint) | Private link |
| <a name="output_project_id"></a> [project\_id](#output\_project\_id) | Mongodb project id |
| <a name="output_region_name"></a> [region\_name](#output\_region\_name) | Mongodb region name |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Authors

Module is maintained by [Alfredo Gottardo](https://github.com/AlfGot), [David Beauvererd](https://github.com/Davidoutz), [Davide Cammarata](https://github.com/DCamma), [Demetrio Carrara](https://github.com/sgametrio) and [Roland Bapst](https://github.com/rbapst-tamedia)

## License

Apache 2 Licensed. See [LICENSE](< link to license file >) for full details.
