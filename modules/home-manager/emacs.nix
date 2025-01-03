{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mjm.emacs;
in
{
  options.mjm.emacs = {
    enable = mkEnableOption "emacs";
  };

  config = mkIf cfg.enable {
    programs.emacs = {
      enable = true;
      package = pkgs.emacs29-pgtk;
      extraPackages = epkgs: [
        epkgs.catppuccin-theme
        epkgs.geiser
        epkgs.geiser-guile
        epkgs.helm
        epkgs.paredit
        epkgs.rainbow-delimiters
      ];
      extraConfig = ''
        (load-theme 'catppuccin :no-confirm)
        (setq catppuccin-flavor 'macchiato)
        (catppuccin-reload)

        (autoload 'enable-paredit-mode "paredit" "Turn on pseudo-structural editing of Lisp code." t)
        (add-hook 'emacs-lisp-mode-hook       #'enable-paredit-mode)
        (add-hook 'eval-expression-minibuffer-setup-hook #'enable-paredit-mode)
        (add-hook 'ielm-mode-hook             #'enable-paredit-mode)
        (add-hook 'lisp-mode-hook             #'enable-paredit-mode)
        (add-hook 'lisp-interaction-mode-hook #'enable-paredit-mode)
        (add-hook 'scheme-mode-hook           #'enable-paredit-mode)

        (put 'with-vat 'scheme-indent-function 'defun)
        (put 'let-on 'scheme-indent-function 'scheme-let-indent)
        (put 'let-on 'scheme-indent-function 'scheme-let-indent)

        (add-hook 'prog-mode-hook #'rainbow-delimiters-mode)

        (require 'helm)
        (require 'helm-autoloads)
        (global-set-key (kbd "M-x") #'helm-M-x)
        (global-set-key (kbd "C-x r b") #'helm-filtered-bookmarks)
        (global-set-key (kbd "C-x C-f") #'helm-find-files)
        (helm-mode 1)

        (setq make-backup-files nil)
        (setq-default indent-tabs-mode nil)
        (set-frame-font "Departure Mono-13")
      '';
    };
  };
}
