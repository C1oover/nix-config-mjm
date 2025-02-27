alias rb := rebuild
alias tfp := tf-plan
alias tfa := tf-apply

rebuild:
  nix run -f . nixos-deploy -- apply-local

gc:
  -nix-collect-garbage --delete-older-than 7d
  -sudo nix-collect-garbage --delete-older-than 7d

deploy *targets:
  nix run -f . nixos-deploy -- deploy {{targets}}

diff host:
  nix run -f . scripts.hosts -- diff {{host}}

repl:
  nix repl -f plans.nix

tf-plan:
  nix run -f . scripts.tofu -- plan

tf-apply:
  nix run -f . scripts.tofu -- apply
