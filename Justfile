alias rb := rebuild
alias sw := switch
alias tfp := tf-plan
alias tfa := tf-apply

rebuild *flags:
  nix run -f . scripts.hosts -- rebuild {{flags}}

switch:
  nix run -f . scripts.hosts -- switch

gc:
  -nix-collect-garbage --delete-older-than 7d
  -sudo nix-collect-garbage --delete-older-than 7d

deploy target *flags:
  nix run -f . scripts.hosts -- deploy {{target}} {{flags}}

diff host:
  nix run -f . scripts.hosts -- diff {{host}}

tf-plan:
  nix run -f . scripts.tofu -- plan

tf-apply:
  nix run -f . scripts.tofu -- apply
