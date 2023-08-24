terraform {
  source = "${get_path_to_repo_root()}/modules/docker-registry/"
  before_hook "interpolation_hook_1" {
    commands     = ["apply", "plan"]
    execute      = ["cp", "${dirname(get_repo_root())}/${basename(get_repo_root())}/modules/docker-registry/variables.tf", "."]
    run_on_error = false
  }
}

locals {
  env_vars = read_terragrunt_config(get_path_to_repo_root())
}

dependency "ingress" {
  config_path = "${get_path_to_repo_root()}/infra/ingress-nginx"
}

inputs = {
  ingress_class = dependency.efs.outputs.ingress_class
  domain_name   = local.env_vars.locals.domain_name
  organization  = local.env_vars.locals.organization
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
