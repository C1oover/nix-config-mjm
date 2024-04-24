alias rb := rebuild
alias sw := switch
alias bt := boot
alias tfp := tf-plan
alias tfa := tf-apply

rebuild *flags:
  $(nix-build -A host-scripts --no-out-link)/bin/rebuild {{flags}}

switch:
  $(nix-build -A host-scripts --no-out-link)/bin/switch

boot:
  $(nix-build -A host-scripts --no-out-link)/bin/switch boot

build target *flags:
  colmena build --on {{target}} --keep-result {{flags}}

deploy target *flags:
  $(nix-build -A host-scripts --no-out-link)/bin/deploy --on {{target}} {{flags}}

tf-clean:
  cd terraform && rm -rf .terraform.lock.hcl .terraform

tf-plan:
  $(nix-build -A tofu-scripts --no-out-link)/bin/tf-plan

tf-apply:
  $(nix-build -A tofu-scripts --no-out-link)/bin/tf-apply

edit-secret file:
  cd secrets && agenix -e {{file}}

rekey:
  cd secrets && agenix -r
