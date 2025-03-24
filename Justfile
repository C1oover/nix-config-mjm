alias rb := rebuild

rebuild:
  nix run -f . dippy -- apply-local

gc:
  -nix-collect-garbage --delete-older-than 7d
  -sudo nix-collect-garbage --delete-older-than 7d

repl:
  nix repl -f plans.nix
