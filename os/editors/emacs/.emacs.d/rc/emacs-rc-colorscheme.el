(add-to-list 'load-path "~/.emacs.d/color-theme-6.6.0")

(require 'color-theme)

(eval-after-load "color-theme"
	'(progn
		(color-theme-initialize)
		(load-file "~/.emacs.d/site-lisp/themes/color-theme-far.el")
		(when window-system
			(color-theme-far-w)
			; active / wombat
			; leuven
		)
		(unless window-system
			(color-theme-far-nw)
		)
	)
)
