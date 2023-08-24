include "eks" {
  path = "${get_path_to_repo_root()}/modules/cluster/terragrunt.hcl"
}

locals {
  env_vars = read_terragrunt_config(get_path_to_repo_root())
}

dependency "vpc" {
  config_path = find_in_parent_folders("01-vpc")
}

inputs = {
  cluster_version = local.env_vars.locals.cluster_version
  cluster_name    = local.env_vars.locals.cluster_name
  vpc_id          = dependency.vpc.outputs.vpc_id
  subnet_ids      = dependency.vpc.outputs.private_subnets
  cluster_security_group_additional_rules = {
    ingress_cluster_to_node_all_traffic = {
      description = "Internal VPC Access"
      protocol = "-1"
      from_port = 0
      to_port = 0
      type = "ingress"
      cidr_blocks = [local.env_vars.locals.cidr]
    }
  }
}

remote_state {
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  backend = local.env_vars.remote_state.backend
  config = merge(
    local.env_vars.remote_state.config,
    {
      key = "${local.env_vars.locals.cluster_full_name}/${basename(get_repo_root())}/${get_path_from_repo_root()}/terraform.tfstate"
    },
  )
}

generate = local.env_vars.generate
