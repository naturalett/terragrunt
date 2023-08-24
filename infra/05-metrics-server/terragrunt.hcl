terraform {
  source = "./"
}

locals {
  env_vars = read_terragrunt_config(get_path_to_repo_root())
}

dependency "eks" {
  config_path = find_in_parent_folders("03-eks")
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