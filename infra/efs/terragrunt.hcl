terraform {
  source = "${get_path_to_repo_root()}/modules/efs/"
  before_hook "interpolation_hook_1" {
    commands     = ["apply", "plan"]
    execute      = ["cp", "${dirname(get_repo_root())}/${basename(get_repo_root())}/modules/efs/variables.tf", "."]
    run_on_error = false
  }
}

locals {
  env_vars   = read_terragrunt_config(get_path_to_repo_root())
  infra_vars = read_terragrunt_config("${get_path_to_repo_root()}/infra/terragrunt.hcl")
}

dependency "eks" {
  config_path = "${get_path_to_repo_root()}/infra/eks"
}

dependency "vpc" {
  config_path = "${get_path_to_repo_root()}/infra/vpc"
}

inputs = {
  efs_policy_name         = local.infra_vars.locals.efs_policy_name
  efs_name                = local.infra_vars.locals.efs_name
  account_id              = local.env_vars.locals.account_id
  private_subnets         = dependency.vpc.outputs.private_subnets
  vpc_id                  = dependency.vpc.outputs.vpc_id
  cluster_oidc_issuer_url = dependency.eks.outputs.cluster_oidc_issuer_url
  oidc_provider_arn       = dependency.eks.outputs.oidc_provider_arn
  cidr_block              = dependency.vpc.outputs.vpc_cidr_block
  node_security_group_id  = dependency.eks.outputs.cluster_primary_security_group_id
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
