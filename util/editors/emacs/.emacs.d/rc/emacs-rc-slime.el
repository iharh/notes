;;; basic load-path setup
;;; ------------------------------------------------------------------

;(defun add-subdirs-to-load-path (dir)
;  (let ((default-directory (concat dir "/"))) ; bind var locally
;    (normal-top-level-add-subdirs-to-load-path)))

;(add-to-list 'load-path "~/.emacs.d/site-lisp")
;(add-subdirs-to-load-path "~/.emacs.d/site-lisp")

;; slime
(add-to-list 'load-path "~/.emacs.d/site-lisp/slime") ; slime | technomancy-slime ; contrib added automatically

(require 'slime)
;(require 'slime-autoloads)


(setq slime-protocol-version 'ignore) ; omit version missmatch warning


(setq slime-lisp-implementations `(
	(sbcl ("sbcl" "--sbcl-nolineedit"))
))

(slime-setup
	'(
		slime-repl	; TODO: customize :bold face, but need to find another face for non-repl cfg
		slime-fuzzy	; for fuzzy completions (including C-c M-i)
		;slime-autodoc	; requires obsolete technomancy slime for compatibility
	)
	;'(slime-fancy) ; almost everything
)

;(defface slime-repl-input-face
;  '((t (:bold t)))
;  "Face for previous input in the SLIME REPL."
;  :group 'slime-repl)

;	`(defun ,name ()

;		(let ((slime-default-lisp ,mapping))

;(defmacro defslime-start (name mapping)
;	`(defun, name ()
;		(interactive)
;		(let ((slime-default-lisp, mapping))
;			(slime)
;		)
;	)
;)

;(defslime-start sbcl 'sbcl)

(defun sbcl ()
	(interactive)
	(let ((slime-default-lisp, 'sbcl))
		(slime)
	)
)

(add-hook 'slime-mode-hook
	(lambda ()
		(setq slime-truncate-lines nil)
;		(slime-redirect-inferior-output) ; patched version with error changed by message
	)
)

;(add-hook 'slime-repl-mode-hook 'split-window-vertically)



(defun slime-jump-to-trace (&optional on)
	"Jump to the file/line that the current stack trace line references. Only works with files in your project root's src/, not in dependencies."
	(interactive)

	(message "!!! slime-jump-to-trace called")

	(save-excursion
		(beginning-of-line)
		(search-forward-regexp "[0-9]: \\([^$(]+\\).*?\\([0-9]*\\))")
		(let (
			(line (string-to-number (match-string 2)))
			(ns-path (split-string (match-string 1) "\\."))
			(project-root (locate-dominating-file default-directory "src/"))
		)
			(find-file (format "%s/src/%s.clj" project-root
				(mapconcat 'identity ns-path "/"))
			)
			(goto-line line)
		)
	)
)

;(eval-after-load 'slime
;	'(progn
;		(defalias 'sldb-toggle-details 'slime-jump-to-trace)
;		(defun sldb-prune-initial-frames (frames)
;			"Show all stack trace lines by default."
;			frames)
;	)
;)
