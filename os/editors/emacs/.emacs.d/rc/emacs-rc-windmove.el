(require 'windmove)

;; setting the PC keyboard's various keys to
;; Super or Hyper, for emacs running on Windows.
(setq
	w32-pass-lwindow-to-system nil
	w32-pass-rwindow-to-system nil
	w32-pass-apps-to-system nil
	w32-lwindow-modifier 'super ; Left Windows key
	w32-rwindow-modifier 'super ; Right Windows key
	w32-apps-modifier 'hyper ; Menu key
) 

(windmove-default-keybindings 'super)
