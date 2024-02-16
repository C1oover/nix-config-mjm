alias rb := rebuild
alias sw := switch
alias tfp := tf-plan
alias tfa := tf-apply

rebuild:
  nix run .#rebuild

switch:
  nix run .#switch

build target *flags:
  colmena build --on {{target}} --keep-result {{flags}}

deploy target *flags:
  nix run .#deploy -- --on {{target}} {{flags}}

unseal target:
  nix run .#unseal -- {{target}}

tf-plan:
  nix run .#tf-plan

tf-apply:
  nix run .#tf-apply

edit-secret file:
  cd secrets && agenix -e {{file}}

rekey:
  cd secrets && agenix -r
