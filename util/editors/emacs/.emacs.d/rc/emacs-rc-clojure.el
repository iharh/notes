;; clojure-mode
(add-to-list 'load-path "~/.emacs.d/site-lisp/clojure-mode") ; contrib added automatically
(require 'clojure-mode)

;(add-to-list 'load-path "~/.emacs.d/site-lisp/swank-clojure/src/emacs")
;(require 'swank-clojure-autoload)
;(setq
;	swank-clojure-jar-path "/usr/local/Cellar/clojure/1.2.0/clojure.jar"
;	swank-clojure-extra-classpaths
;	(list
;		"~/.emacs.d/swank-clojure/src/main/clojure"
;		"/usr/local/Cellar/clojure-contrib/1.2.0/clojure-contrib.jar")
;)

; disable slime autodoc
(setq slime-use-autodoc-mode nil)

;(defun define-function ()
;	(interactive)
;	(let 
;		((name (symbol-at-point)))

;		(backward-paragraph)
;		(insert "\n(defn " (symbol-name name) "\n  [])\n")
;		(backward-char 3)
;	)
;)

;(define-key clojure-mode-map (kbd "C-c f") 'define-function)



(add-to-list 'load-path "~/.emacs.d/site-lisp/elein")
; !!! PATCH elein.el !!!
;(defun elein-swank-process-filter (process output)
;	"Swank process filter to launch `slime-connect' when process is ready."
;	(with-current-buffer elein-swank-buffer-name (insert output))
;	(when (string-match "Connection opened on" output)
;		(slime-set-inferior-process
;			(slime-connect "localhost" elein-swank-port)
;			process
;		)
;		(set-process-filter process nil)
;	)
;)
(require 'elein)

(setq elein-swank-options "")
; ":encoding '\"utf-8\"'"

; http://bc.tech.coop/blog/081120.html - SLIME doc / javadoc
