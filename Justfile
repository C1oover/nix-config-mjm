alias rb := rebuild
alias sw := switch
alias bt := boot
alias tfp := tf-plan
alias tfa := tf-apply

rebuild *flags:
  nix run -f . host-scripts -- rebuild {{flags}}

switch:
  nix run -f . host-scripts -- switch

boot:
  nix run -f . host-scripts -- switch boot

gc:
  nix-collect-garbage --delete-older-than 7d
  sudo nix-collect-garbage --delete-older-than 7d

build target *flags:
  colmena build --on {{target}} --keep-result {{flags}}

deploy target *flags:
  nix run -f . host-scripts -- deploy --on {{target}} {{flags}}

diff host:
  nix run -f . host-scripts -- diff {{host}}

tf-clean:
  cd terraform && rm -rf .terraform.lock.hcl .terraform

tf-plan:
  nix run -f . tofu-scripts -- plan

tf-apply:
  nix run -f . tofu-scripts -- apply
