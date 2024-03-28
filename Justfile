alias rb := rebuild
alias sw := switch
alias bt := boot
alias tfp := tf-plan
alias tfa := tf-apply

rebuild *flags:
  nix run .#rebuild -- {{flags}}

switch:
  nix run .#switch

boot:
  nix run .#switch -- boot

build target *flags:
  colmena build --on {{target}} --keep-result {{flags}}

deploy target *flags:
  nix run .#deploy -- --on {{target}} {{flags}}

unseal target:
  nix run .#unseal -- {{target}}

tf-clean:
  cd terraform && rm -rf .terraform.lock.hcl .terraform

tf-plan:
  nix run .#tf-plan

tf-apply:
  nix run .#tf-apply

edit-secret file:
  cd secrets && agenix -e {{file}}

rekey:
  cd secrets && agenix -r
