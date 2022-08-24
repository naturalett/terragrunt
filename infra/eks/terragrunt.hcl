include "eks" {
  path = "${get_path_to_repo_root()}/modules/cluster/terragrunt.hcl"
}

locals {
  env_vars = read_terragrunt_config(get_path_to_repo_root())
}

dependency "vpc" {
  config_path = "${get_path_to_repo_root()}/infra/vpc"
}

inputs = {
  cluster_version = local.env_vars.locals.cluster_version
  cluster_name    = local.env_vars.locals.cluster_name
  vpc_id          = dependency.vpc.outputs.vpc_id
  subnet_ids      = dependency.vpc.outputs.private_subnets
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
