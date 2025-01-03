(require-builtin helix/core/editor as helix.)
(provide Action/Load)
(define (Action/Load)
    (helix.Action/Load))

(provide Action/Replace)
(define (Action/Replace)
    (helix.Action/Replace))

(provide Action/HorizontalSplit)
(define (Action/HorizontalSplit)
    (helix.Action/HorizontalSplit))

(provide Action/VerticalSplit)
(define (Action/VerticalSplit)
    (helix.Action/VerticalSplit))

(provide editor-focus)
(define (editor-focus)
    (helix.editor-focus *helix.cx*))

(provide editor-mode)
(define (editor-mode)
    (helix.editor-mode *helix.cx*))

(provide cx->themes)
(define (cx->themes)
    (helix.cx->themes *helix.cx*))

(provide editor-all-documents)
(define (editor-all-documents)
    (helix.editor-all-documents *helix.cx*))

(provide cx->cursor)
(define (cx->cursor)
    (helix.cx->cursor *helix.cx*))

(provide editor-focused-buffer-area)
(define (editor-focused-buffer-area)
    (helix.editor-focused-buffer-area *helix.cx*))

(provide editor->doc-id)
(define (editor->doc-id arg)
    (helix.editor->doc-id *helix.cx* arg))

(provide editor-switch!)
(define (editor-switch! arg)
    (helix.editor-switch! *helix.cx* arg))

(provide editor-set-focus!)
(define (editor-set-focus! arg)
    (helix.editor-set-focus! *helix.cx* arg))

(provide editor-set-mode!)
(define (editor-set-mode! arg)
    (helix.editor-set-mode! *helix.cx* arg))

(provide editor-doc-in-view?)
(define (editor-doc-in-view? arg)
    (helix.editor-doc-in-view? *helix.cx* arg))

(provide set-scratch-buffer-name!)
(define (set-scratch-buffer-name! arg)
    (helix.set-scratch-buffer-name! *helix.cx* arg))

(provide editor-doc-exists?)
(define (editor-doc-exists? arg)
    (helix.editor-doc-exists? *helix.cx* arg))

(provide editor->text)
(define (editor->text arg)
    (helix.editor->text *helix.cx* arg))

(provide editor-document->path)
(define (editor-document->path arg)
    (helix.editor-document->path *helix.cx* arg))

(provide set-editor-clip-top!)
(define (set-editor-clip-top! arg)
    (helix.set-editor-clip-top! *helix.cx* arg))

(provide set-editor-clip-right!)
(define (set-editor-clip-right! arg)
    (helix.set-editor-clip-right! *helix.cx* arg))

(provide set-editor-clip-left!)
(define (set-editor-clip-left! arg)
    (helix.set-editor-clip-left! *helix.cx* arg))

(provide set-editor-clip-bottom!)
(define (set-editor-clip-bottom! arg)
    (helix.set-editor-clip-bottom! *helix.cx* arg))

(provide editor-switch-action!)
(define (editor-switch-action! arg1 arg2)
    (helix.editor-switch-action! *helix.cx* arg1 arg2))
