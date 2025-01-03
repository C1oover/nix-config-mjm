(require-builtin steel/process as process.)
(require (prefix-in helix. "helix/commands.scm"))
(require (prefix-in helix.static. "helix/static.scm"))
(require "helix/editor.scm")

(provide run-mix
         kitty-run
         test-all
         test-current-file
         test-previous
         test-current-line
         open-in-github
         search-selection-in-dash)

(define previous-test #f)

;;@doc
;; Run all tests
(define (test-all)
  (run-mix "test"))

;;@doc
;; Run tests in the current file
(define (test-current-file)
  (set! previous-test (current-relative-path))
  (test-previous))

;;@doc
;; Run the test from the current line
(define (test-current-line)
  (set!
   previous-test
   (string-append (current-relative-path) ":" (to-string (helix.static.get-current-line-number))))
  (test-previous))

;;@doc
;; Re-run the last test
(define (test-previous)
  (if (not previous-test) (error! "no previous test saved") (run-mix "test" previous-test)))

(define (open-in-github)
  (let ([path (current-relative-path)] [line (to-string (helix.static.get-current-line-number))])
    (helix.run-shell-command "gh browse" (string-append path ":" line))))

; (define (open-url url)
;   (if (darwin?)
;       (helix.run-shell-command "open" url)
;       (helix.run-shell-command "xdg-open" url)))

; (define (run-command cmd args)
;   (~> (process.command cmd args)
;       (process.spawn-process)
;       (process.wait->stdout)))

; (define (darwin?)
;   (equal? "Darwin" (trim-end (run-command "uname" '()))))

;;@doc
;; Search selected text in Dash
(define (search-selection-in-dash)
  (let ([url (string-append "dash://?query=" (helix.static.current-highlighted-text!))])
    (helix.run-shell-command "open" url)))

(define (current-path)
  (let* ([focus (editor-focus)]
         [focus-doc-id (editor->doc-id focus)])

    (if (editor-doc-exists? focus-doc-id) (editor-document->path focus-doc-id) #f)))

(define (current-relative-path)
  (let* ([workspace-path (helix-find-workspace)] [file-path (to-string (current-path))])
    (strip-path-prefix file-path workspace-path)))

(define (strip-path-prefix path prefix)
  (if (starts-with? path prefix)
      (substring path (+ 1 (string-length prefix)) (string-length path))
      (error! "bad path")))

(define (slab-workspace?)
  (equal? "slab" (file-name (helix-find-workspace))))

(define (kitty-run name . args)
  (let ([cmd (string-join args " ")])
    (helix.run-shell-command "zellij"
                             "run"
                             "--floating"
                             (string-append "--name='" name "'")
                             "--"
                             "`which nu`"
                             "-li"
                             "-c"
                             (string-append "'" cmd "'")
                             ">/dev/null")))

(define (run-mix . args)
  (let ([mix (if (slab-workspace?) "docker compose exec slab_1 mix" "mix")]
        [name (string-append "mix " (string-join args " "))])
    (apply kitty-run (cons name (cons mix args)))))
