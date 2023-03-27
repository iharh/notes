(require 'ido)

(ido-mode t)
(ido-everywhere t)

(setq ido-enable-flex-matching t)

(setq
	ido-cannot-complete-command 'ido-next-match
	ido-default-buffer-method 'selected-window
	ido-default-file-method 'selected-window
	ido-auto-merge-work-directories-length -1
	ido-max-window-height 6
	ido-ignore-directories '("\\`auto/" "\\.prv/" "\\`CVS/" "\\`\\.\\./" "\\`\\./")
)

(global-set-key "\M-x"
	(lambda () (interactive)
		(call-interactively
			(intern
				(ido-completing-read "M-x "
					(all-completions "" obarray 'commandp)
				)
			)
		)
	)
)

; ido-create-new-buffer 'always 'prompt 'never
; ido-enable-trump-completion nil
; ido-enable-last-directory-history nil
; ido-confirm-unique-completion nil
; ido-show-dot-for-dired t ; put . as the first item
; ido-use-filename-at-point 'guess ; prefer file names near point
; (setq ido-file-extensions-order '(".org" ".txt" ".py" ".emacs" ".xml" ".el" ".ini" ".cfg" ".cnf"))

(add-hook 'ido-minibuffer-setup-hook
	(function
		(lambda ()
			(make-local-variable 'max-mini-window-height)
			(setq max-mini-window-height 3)
;			(make-local-variable 'resize-minibuffer-window-max-height)
;			(setq resize-minibuffer-window-max-height 10)
		)
	)
)
