(custom-set-variables
	'(default-input-method "russian-computer")
;; inihibits
	'(backup-inhibited t)
	'(inhibit-startup-screen t)
;; (defcustom bla-bla-bla
	;; '(transient-mark-mode t)
;; inhibit hallow cursors in inactive windows
	'(cursor-in-non-selected-windows nil)
;; backup
;;
;;	'(scroll-bar-mode-explicit t)
;;	'(set-scroll-bar-mode `right)
)

(custom-set-faces
	;; custom-set-faces was added by Custom.
	;; If you edit it by hand, you could mess it up, so be careful.
	;; Your init file should contain only one such instance.
	;; If there is more than one, they won't work right.
	'(default ((t (:family "Command Prompt 10x18" :height 120))))

	; TODO: try set-face-bold-p (modify-face set-face-attribute)

	;;  :width normal :weight normal :slant normal :background "#f8f8ff" :foreground "#000000" :inverse-video nil :box nil :strike-through nil :overline nil :underline nil :foundry "outline" :inherit nil :stipple nil

	; :family "Command Prompt 10x18" :height 120

	;; :family "Bitstream Vera Sans Mono" :height 143
	;; :family "DejaVu Sans Mono" :height 143
	;; :family "Consolas" :height 143
	;; :family "Inconsolata" :height 158
	;; :family "Anonymous Pro" :height 143
	;; Lucida Console
)


;;(set-input-method "russian-computer" nil)
;;(setenv "LANG" "ru_RU.UTF-8")

;; disable extra ...
(tool-bar-mode 0)
(menu-bar-mode 0) ;; Use C-<right mouse> to open global menu

;;(column-number-mode t)


;;(setq scroll-bar-mode-explicit t)
;;(set-scroll-bar-mode `right) - gui version only

;; use y/n instead of yes/no
(fset 'yes-or-no-p 'y-or-n-p)


;; backspace don't kill tab
(setq c-backspace-function 'delete-backward-char) ;; backward-delete-char-untabify is not a good for me

;; cursor type - works for window-mode only
(set-default 'cursor-type 'bar)

;; don't wrap lines
(set-default 'truncate-lines t)

;; mode-line
;; mode-line-in-non-selected-windows nil

;;(size-indication-mode t)


;; M-x load-file ~/.emacs

;;(message "hello world!")

;(windmove-default-keybindings 'meta) ;; ??? - at windmove.el