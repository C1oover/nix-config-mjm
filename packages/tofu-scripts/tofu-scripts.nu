use nu-lib/vault.nu *

def link-tf-config [] {
  ln -sf $env.TF_CONFIG terraform/config.tf.json
}

export def with-tofu [block] {
  link-tf-config
  cd terraform
  do $block
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
