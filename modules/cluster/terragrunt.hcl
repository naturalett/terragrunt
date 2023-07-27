terraform {
  # https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
  # https://github.com/terraform-aws-modules/terraform-aws-eks/tree/v19.14.0
  source = "tfr:///terraform-aws-modules/eks/aws?version=19.14.0"
  after_hook "terragrunt-read-config" {
    commands = ["apply"]
    execute  = ["bash", "./script.sh"]
  }
  extra_arguments "set_env" {
    commands = ["apply"]
    env_vars = {
      CLUSTER_NAME = local.env_vars.locals.cluster_full_name
      region_code  = local.env_vars.locals.aws_region
      cluster_name = local.env_vars.locals.cluster_name
      account_id   = local.env_vars.locals.account_id
    }
  }
}

locals {
  env_vars = read_terragrunt_config(get_path_to_repo_root())
}