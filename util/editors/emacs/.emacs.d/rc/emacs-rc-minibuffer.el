;(setq
;	enable-recursive-minibuffers nil         ;;  allow mb cmds in the mb
;;	max-mini-window-height .25             ;;  max 2 lines
;	max-mini-window-height .50
;	max-mini-window-height nil
;	minibuffer-scroll-window nil
;	resize-mini-windows nil
;)

(add-hook 'minibuffer-setup-hook
	(function
		(lambda ()
			(make-local-variable 'truncate-lines)
			(setq truncate-lines nil)
		)
	)
)
