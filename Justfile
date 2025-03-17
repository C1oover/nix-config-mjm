alias rb := rebuild
alias tfp := tf-plan
alias tfa := tf-apply

rebuild:
  nix run -f . dippy -- apply-local

gc:
  -nix-collect-garbage --delete-older-than 7d
  -sudo nix-collect-garbage --delete-older-than 7d

repl:
  nix repl -f plans.nix

tf-plan:
  nix run -f . scripts.tofu -- plan

tf-apply:
  nix run -f . scripts.tofu -- apply
