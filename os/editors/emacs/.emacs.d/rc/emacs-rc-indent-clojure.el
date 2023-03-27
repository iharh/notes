(add-hook 'clojure-mode-hook
	(lambda ()
		(set (make-local-variable 'lisp-indent-function) nil) ; 'clojure-indent-function
		(set (make-local-variable 'indent-line-function) 'indent-relative-maybe) ; 'lisp-indent-line / 'insert-tab / 'indent-relative

		(define-key clojure-mode-map (kbd "RET") 'newline-and-indent) ; 'reindent-then-newline-and-indent
	)
)

; (setq clojure-mode-use-backtracking-indent t) ; experimental
; (global-set-key (kbd "C-m") 'newline-and-indent)
; (add-hook 'slime-connected-hook (lambda () (require 'clojure-mode)))
;; SLIME Keys
;(define-key slime-mode-map (kbd "TAB") 'slime-indent-and-complete-symbol)


;(defvar clojure-mode-map
;  (let ((map (make-sparse-keymap)))
;    (set-keymap-parent map lisp-mode-shared-map)
;    (define-key map "\e\C-x" 'lisp-eval-defun)
;    (define-key map "\C-x\C-e" 'lisp-eval-last-sexp)
;    (define-key map "\C-c\C-e" 'lisp-eval-last-sexp)
;    (define-key map "\C-c\C-l" 'clojure-load-file)
;    (define-key map "\C-c\C-r" 'lisp-eval-region)
;    (define-key map "\C-c\C-z" 'run-lisp)
;    (define-key map (kbd "RET") 'reindent-then-newline-and-indent) ; !!!
;    map)
;  "Keymap for Clojure mode. Inherits from `lisp-mode-shared-map'.")

;(defun clojure-mode ()
;...
;  (set (make-local-variable 'lisp-indent-function)
;       'clojure-indent-function)

; ??? lisp-indent-offset var



;(defun insert-tab ()
;	"self-insert-command doesn't seem to work for tab"
;	(interactive)
;	(insert "\t")
;)

; (setq indent-line-function 'insert-tab)  ;# for many modes


;; Fix the worse part about emacs: indentation craziness
;;   1. When I hit the TAB key, I always want a TAB character inserted
;;   2. Don't automatically indent the line I am editing.
;;   3. When I hit C-j, I always want a newline, plus enough tabs to put me on
;;      the same column I was at before.
;;   4. When I hit the BACKSPACE key to the right of a TAB character, I want the
;;      TAB character deleted-- not replaced with tabwidth-1 spaces.
;(defun newline-and-indent-relative ()
;	"Insert a newline, then indent relative to the previous line."
;	(interactive "*")
;	(newline)
;	(indent-relative)
;)
; DANGER
;(defun indent-according-to-mode () ())
;(defalias 'newline-and-indent 'newline-and-indent-relative)
