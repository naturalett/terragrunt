terraform {
  source = "${dirname(get_repo_root())}/${basename(get_repo_root())}/modules/pvc/"
  before_hook "interpolation_hook_1" {
    commands     = ["apply", "plan"]
    execute      = ["cp", "${dirname(get_repo_root())}/${basename(get_repo_root())}/modules/pvc/variables.tf", "."]
    run_on_error = false
  }
}

dependency "efs" {
  config_path = "${get_path_to_repo_root()}/infra/02-efs"
}

locals {
  env_vars = read_terragrunt_config(get_path_to_repo_root())
}

inputs = {
  efsVolume_id = dependency.efs.outputs.efsVolume_id
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
