;(setq cua-mode t)
;(setq cua-keep-region-after-copy t) ;; Standard Windows behaviour

;(setq cua-selection-mode t) - by it's own don't allow us to use (cua-keep-region-after-copy)
;	(setq cua-auto-tabify-rectangles nil) ;; Don't tabify after rectangle commands

;(transient-mark-mode 1) ;; No region when it is not highlighted
(delete-selection-mode t)       ; delete the selection area with a keypress
