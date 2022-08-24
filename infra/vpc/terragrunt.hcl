include "vpc" {
  path = "${dirname(get_repo_root())}/${basename(get_repo_root())}/modules/vpc/terragrunt.hcl"
}

locals {
  env_vars = read_terragrunt_config(get_path_to_repo_root())
}

inputs = {
  name = local.env_vars.locals.cluster_name
  cidr = local.env_vars.locals.cidr

  azs             = local.env_vars.locals.azs
  private_subnets = local.env_vars.locals.private_subnets
  public_subnets  = local.env_vars.locals.public_subnets

  enable_nat_gateway = true
  enable_vpn_gateway = true

  private_subnet_tags = {
    Tier                                                          = "Private"
    "kubernetes.io/role/internal-elb"                             = 1
    "kubernetes.io/cluster/${local.env_vars.locals.cluster_name}" = "owned"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb"                                      = 1
    "kubernetes.io/cluster/${local.env_vars.locals.cluster_name}" = "owned"
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
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
