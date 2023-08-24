include "eks-managed-node-group" {
  path = "${get_path_to_repo_root()}/modules/eks-managed-node-group/terragrunt.hcl"
}

locals {
  env_vars = read_terragrunt_config(get_path_to_repo_root())
}

dependency "eks" {
  config_path = "${get_path_to_repo_root()}/infra/03-eks"
}

dependency "vpc" {
  config_path = "${get_path_to_repo_root()}/infra/01-vpc"
}

# EFS output: https://github.com/kabisa/terraform-aws-eks-alb-ingress/blob/master/README.md
dependency "efs" {
  config_path = "${get_path_to_repo_root()}/infra/02-efs"
}

inputs = {
  name         = "internal-services"
  cluster_name = local.env_vars.locals.cluster_name

  desired_size = 1
  max_size     = 3
  min_size     = 1

  instance_types        = ["t3.large"]
  capacity_type         = "SPOT"
  create_security_group = false

  cluster_primary_security_group_id = dependency.eks.outputs.cluster_primary_security_group_id
  cluster_security_group_id         = dependency.eks.outputs.cluster_security_group_id
  # vpc_security_group_ids            = [dependency.eks.outputs.node_security_group_id]
  node_role_arn                = dependency.eks.outputs.cluster_iam_role_arn
  subnet_ids                   = dependency.vpc.outputs.private_subnets
  cluster_endpoint             = dependency.eks.outputs.cluster_endpoint
  cluster_auth_base64          = dependency.eks.outputs.cluster_certificate_authority_data
  iam_role_additional_policies = [dependency.efs.outputs.aws_iam_policy_arn]

  labels = {
    Environment   = "test"
    GithubRepo    = "terraform-aws-eks"
    GithubOrg     = "terraform-aws-modules"
    node_selector = "internal-services"
  }

  taints = {
    dedicated = {
      key    = "dedicated"
      value  = "gpuGroup"
      effect = "PREFER_NO_SCHEDULE"
    }
  }

  tags = {
    Environment = "test"
    Terraform   = "true"
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
