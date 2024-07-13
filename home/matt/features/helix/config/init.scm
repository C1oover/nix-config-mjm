(require-builtin helix/core/keymaps as helix.keymaps.)
(require "helix/configuration.scm")

;;@doc
;; Add keybinding to the global default
(define (add-global-keybinding map)
  ;; Copy the global ones
  (define global-bindings (get-keybindings))
  (helix.keymaps.helix-merge-keybindings
   global-bindings
   (~> map (value->jsexpr-string) (helix.keymaps.helix-string->keymap)))

  (keybindings global-bindings))

(add-global-keybinding
  (hash "normal"
        (hash "space"
              (hash "t"
                    (hash "a" ":test-all"
                          "f" ":test-current-file"
                          "l" ":test-current-line"
                          "t" ":test-previous")))))
