(add-to-list 'load-path "~/.emacs.d/auto-complete")
(require 'auto-complete-config)

(add-to-list 'ac-dictionary-directories "~/.emacs.d/auto-complete/ac-dict") ; //ad-dict
(ac-config-default)

(define-key ac-completing-map "\e" 'ac-stop) ; "\ESC/"

; ac-slime
(setq load-path (cons "~/.emacs.d/site-lisp/ac-slime" load-path))
(require 'ac-slime)
;(add-hook 'slime-mode-hook 'set-up-slime-ac)
;(add-hook 'slime-repl-mode-hook 'set-up-slime-ac)
;(setq ac-slime-current-doc t)


;(setq ac-use-quick-help t)
;ac-quick-help-delay


; https://github.com/purcell/emacs.d/blob/master/init-auto-complete.el

;(require 'auto-complete)
;(require 'auto-complete-config)
;(global-auto-complete-mode t)
;(setq ac-auto-start nil)
;(setq ac-dwim t)
;(define-key ac-completing-map (kbd "C-n") 'ac-next)
;(define-key ac-completing-map (kbd "C-p") 'ac-previous)