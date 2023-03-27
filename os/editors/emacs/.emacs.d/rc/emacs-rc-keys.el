(require 'misc)


(global-set-key [C-tab] 'next-buffer)

;;(define-key global-map [prior] 'scroll-down)
;;(define-key global-map [next]  'scroll-up)

;; we use (lambda () (interactive) ... ) here only because global needs it

(global-set-key [next]
	(lambda () (interactive)
		(condition-case nil (scroll-up)
			(end-of-buffer (goto-char (point-max)))
		)
	)
)
  
(global-set-key [prior]
	(lambda () (interactive)
		(condition-case nil (scroll-down)
			(beginning-of-buffer (goto-char (point-min)))
		)
	)
)


(global-set-key [C-f4] 
	(lambda () (interactive)
		;; use (defconst ...) for predefined buffers list
		(if
			(and
				(not (one-window-p))
				(member (buffer-name) ;;(string-equal (buffer-name) "*Help*") 
					'(
						"*Apropos*" "*Man*" "*Help*" "*Buffer List*" "*Compile-Log*" "*info*" "*vc*"
						"*vc-diff*" "*diff*"
						"*Backtrace*" "*RE-Builder*"
					)
				)
			)
			(kill-buffer-and-window)
			(kill-this-buffer)
		)
	)
)

(global-set-key [M-f4] 'save-buffers-kill-emacs)

(global-set-key [f5] ;; Ñ-right
	(lambda () (interactive)
		(message "Hello f5 - this is undefined and used for testing only now!")
	)
)

(global-set-key [C-right] ;; Ñ-right
	(lambda ()
		(interactive "^") ; very important for shift-translation
		(forward-to-word 1)
	)
)

;;(global-set-key [M-f4]
;;	(lambda () (interactive)
		;;'("*Help*" "*Apropos*" "*Man " "*Buffer List*" "*Compile-Log*" "*info*" "*vc*" "*vc-diff*" "*diff*")

		;; print buffer names
		;;(dolist (li (buffer-list))
		;;	(message (buffer-name li))
		;;)

		;; (funcall - dynamically call func by name/id

		;;(progn
		;;	(message "Current buffer name is:")
		;;	(message (buffer-name)) ;; current-buffer
		;;)

		;; (when cond action1 action2 ...)
		;; (if cont then-action else-action)
		;; (message (buffer-list))

		;; see (defun clean-buffer-list () at midnight.el - line 166
;;	)
;;)


(global-set-key (kbd "C-w") 'kill-this-buffer) ; was mapped to kill-region
;(global-set-key (kbd "C-o") 'find-file) ; was mapped to open-line - insert a new line

;(global-set-key (kbd "C-a") 'mark-whole-buffer) ; mapped to move-beginning-of-line

;(global-set-key "\C-s" 'save-buffer) ; conflict with emacs search
;(global-set-key "\C-f" 'isearch-forward)
;(define-key isearch-mode-map "\C-f" 'isearch-repeat-forward)



(global-set-key (kbd "M-DEL") 'undo)
;;(global-set-key (kbd "M-S-DEL") 'redo)

(global-set-key (kbd "C-x <up>") 'windmove-up)
(global-set-key (kbd "C-x <down>") 'windmove-down)
;(global-set-key (kbd "C-x <right>") 'windmove-right)
;(global-set-key (kbd "C-x <left>") 'windmove-left)


;; view-mode-hook
(add-hook 'help-mode-hook
	(lambda ()
		(local-set-key (kbd "b") 'help-go-back)
		(local-set-key (kbd "f") 'help-go-forward)
	)
)

;; cc-mode-common-hook - c-mode-hook don't work - try c++-mode-hook also
(add-hook 'c-mode-common-hook
	(lambda ()
		(local-set-key (kbd "RET") 'newline-and-indent) ;; for indent via ret
;;		(local-set-key [M-f4] (lambda () (interactive) (message "Hello!!!")))
	)
)
