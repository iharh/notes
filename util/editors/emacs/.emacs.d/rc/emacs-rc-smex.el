;### Persistence
;Smex keeps a file to save its state betweens Emacs sessions. The
;default path is "~/.smex-items"; you can change it by setting the
;variable `smex-save-file`.

(add-to-list 'load-path "~/.emacs.d/site-lisp/smex") ; contrib added automatically
(require 'smex)

(smex-initialize)

(setq smex-save-file "~/.emacs.d/smex/.smex-items")
(setq smex-auto-update t)

(global-set-key (kbd "M-x") 'smex)
(global-set-key (kbd "M-X") 'smex-major-mode-commands)
;; This is your old M-x.
(global-set-key (kbd "C-c C-c M-x") 'execute-extended-command)
