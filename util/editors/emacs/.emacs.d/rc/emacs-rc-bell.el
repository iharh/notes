;; disable bell (beep)
(defun my-bell-function ()
	(unless
		(memq this-command
			'(isearch-abort
				next-line previous-line backward-char forward-char
				scroll-up scroll-down cua-scroll-up cua-scroll-down
				down up
				keyboard-quit exit-minibuffer abort-recursive-edit
				mwheel-scroll 
			)
		)
		(ding)
	)
)

(setq ring-bell-function 'my-bell-function)
