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
  with-vault {
    with-tofu {
      tofu init
      tofu plan
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
