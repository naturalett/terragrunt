include "efs" {
  path = "${get_path_to_repo_root()}/infra/eks/terragrunt.hcl"
}


inputs = {
  cluster_name    = "${local.env_vars.locals.cluster_name}-test"
}