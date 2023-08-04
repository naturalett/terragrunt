# https://aws.amazon.com/blogs/opensource/network-load-balancer-nginx-ingress-controller-eks/
# https://aws.amazon.com/blogs/opensource/network-load-balancer-nginx-ingress-controller-eks/
# https://easoncao.com/eks-best-practice-load-balancing-3-en/#fn:aws-lb-controller-ingressgroup
# https://github.com/kubernetes/ingress-nginx/blob/nginx-0.30.0/docs/user-guide/nginx-configuration/annotations.md
terraform {
  source = "${get_path_to_repo_root()}/modules/ingress-nginx/"
}

locals {
  env_vars   = read_terragrunt_config(get_path_to_repo_root())
  infra_vars = read_terragrunt_config("${get_path_to_repo_root()}/infra/terragrunt.hcl")
}

inputs = {
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
