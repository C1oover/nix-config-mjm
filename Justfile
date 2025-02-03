alias rb := rebuild
alias tfp := tf-plan
alias tfa := tf-apply

rebuild *flags:
  nix run -f . scripts.hosts -- rebuild {{flags}}

gc:
  -nix-collect-garbage --delete-older-than 7d
  -sudo nix-collect-garbage --delete-older-than 7d

deploy target *flags:
  nix run -f . scripts.hosts -- deploy {{target}} {{flags}}

diff host:
  nix run -f . scripts.hosts -- diff {{host}}

repl:
  nix repl -f plans.nix

tf-plan:
  nix run -f . scripts.tofu -- plan

tf-apply:
  nix run -f . scripts.tofu -- apply
