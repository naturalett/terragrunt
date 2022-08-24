terraform {
  source = "${get_path_to_repo_root()}/modules/aws-load-balancer-controller/"

}

dependency "vpc" {
  config_path = "${get_path_to_repo_root()}/infra/vpc"
}

dependency "eks" {
  config_path = "${get_path_to_repo_root()}/infra/eks"
}

locals {
  env_vars   = read_terragrunt_config(get_path_to_repo_root())
  infra_vars = read_terragrunt_config("${get_path_to_repo_root()}/infra/terragrunt.hcl")
}

inputs = {
  vpc_id                  = dependency.vpc.outputs.vpc_id
  clusterName             = local.env_vars.locals.cluster_name
  aws_region              = local.env_vars.locals.aws_region
  account_id              = local.env_vars.locals.account_id
  alb_policy_name         = local.infra_vars.locals.alb_policy_name
  cluster_oidc_issuer_url = dependency.eks.outputs.cluster_oidc_issuer_url
  oidc_provider           = dependency.eks.outputs.oidc_provider
  oidc_provider_arn       = dependency.eks.outputs.oidc_provider_arn
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
