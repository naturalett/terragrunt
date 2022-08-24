locals {
  global_vars = yamldecode(file("values.yaml"))
}

dependency "eks" {
  config_path = "${get_path_to_repo_root()}/infra/eks"
}

inputs = {
  cluster_identity_oidc_issuer_arn = dependency.eks.outputs.oidc_provider_arn,
  cluster_identity_oidc_issuer     = dependency.eks.outputs.cluster_oidc_issuer_url,
  settings = {
    replicaCount = local.global_vars.replicaCount
  }
}
