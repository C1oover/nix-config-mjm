alias rb := rebuild
alias sw := switch
alias bt := boot
alias tfp := tf-plan
alias tfa := tf-apply

rebuild *flags:
  nix run -f . rebuild -- {{flags}}

switch:
  nix run -f . switch

boot:
  nix run -f . switch -- boot

build target *flags:
  colmena build --on {{target}} --keep-result {{flags}}

deploy target *flags:
  nix run -f . host-scripts -- deploy --on {{target}} {{flags}}

tf-clean:
  cd terraform && rm -rf .terraform.lock.hcl .terraform

tf-plan:
  nix run -f . tf-plan

tf-apply:
  nix run -f . tf-apply

edit-secret file:
  cd secrets && agenix -e {{file}}

rekey:
  cd secrets && agenix -r
