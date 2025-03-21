use nu-lib/vault.nu *

def with-tofu [block] {
  let config_dir = mktemp -d
  let config_dest = $config_dir | path join "config.tf.json"
  ln -s $env.TF_CONFIG $config_dest

  let old_pwd = pwd
  cd $config_dir

  try {
    do -c $block
    cd $old_pwd
    rm -rf $config_dir
  } catch {|e|
    cd $old_pwd
    rm -rf $config_dir
  }
}

def --wrapped "main plan" [...args] {
  with-tofu {
    tofu init
    tofu plan ...$args
  }
}

def --wrapped "main apply" [...args] {
  with-tofu {
    tofu init
    tofu apply ...$args
  }
}

def "main ci plan" [] {
  let old_pwd = pwd

  with-vault {
    with-tofu {
      tofu init
      tofu plan -out=plan.cache

      # adapted from https://docs.gitlab.com/user/infrastructure/iac/mr_integration/
      let plan = tofu show -json plan.cache | from json
      let actions = $plan.resource_changes.change.actions | flatten
      let report = {
        create: ($actions | where {|el| $el == "create" } | length)
        update: ($actions | where {|el| $el == "update" } | length)
        delete: ($actions | where {|el| $el == "delete" } | length)
      }

      $report | save $'($old_pwd)/plan.json'
    }
  }
}

def "main ci apply" [] {
  with-vault {
    with-tofu {
      tofu init
      tofu apply -auto-approve
    }
  }
}

def main [] {}
