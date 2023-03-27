;; (defalias 'sc 'slime-connect)

;; clojure stuff

(defun clojure-swank ()
	(interactive)
	(let ((root (locate-dominating-file default-directory "project.clj")))
		(when (not root)
			(error "Not in a Leiningen project.")
		)
;		(message (format "root: %s port: %s" root slime-port))

		;; you can customize slime-port using .dir-locals.el
;		(shell-command (format "cd %s && lein swank %s &" root slime-port) "*lein-swank*")
		(shell-command (format "cd %s && lein swank %s &" "D:\\dev\\Clojure\\prj\\myprj" slime-port) "*clojure-swank*")

		(set-process-filter (get-buffer-process "*clojure-swank*")
			(lambda (process output)
				(when (string-match "Connection opened on" output)
					(slime-connect "localhost" slime-port)
					(set-process-filter process nil)	
				)
			)
		)
		(message "Starting swank server...")
	)
)


(defun clojure-swank-1 ()
	"Launch swank-clojure from users homedir/.lein/bin"
	(interactive)
	(let ((buffer (get-buffer-create "*clojure-swank*")))
		(flet ((display-buffer (buffer-or-name &optional not-this-window frame) nil))
			(bury-buffer buffer)
			(shell-command "~/.lein/bin/swank-clojure &" buffer)
		)

		(set-process-filter (get-buffer-process buffer)
			(lambda (process output)
				(with-current-buffer "*clojure-swank*" (insert output))
					(when (string-match "Connection opened on local port +\\([0-9]+\\)" output)
						(slime-connect "localhost" (match-string 1 output))
						(set-process-filter process nil)
					)
			)
		)
		(message "Starting swank server... ")
	)
)


(defun clojure-kill-swank ()
	"Kill swank process started by lein swank."
	(interactive)
	(let ((process (get-buffer-process "*clojure-swank*")))
		(when process
			(ignore-errors (slime-quit-lisp))
			(let ((timeout 10))
				(while (and (> timeout 0) (eql 'run (process-status process)))
					(sit-for 1)
					(decf timeout)
				)
			)
			(ignore-errors (kill-buffer "*clojure-swank*"))
		)
	)
)



; (let [x 1] (swank.core/break)) -> slime-fancy


; I can easily compile and load with C-c C-k, reload every function with C-M-x and everything that is standard in slime.
; It seems that functions in src/projectname/core.clj can be used directly when they are loaded with C-M-k,
; but not with C-c C-k. However, I find more useful to do the latter most of the times. Moreover, I believe that files outside src do not load directly in user. Besides, I prefer not to. As a consequence I switch namespace in slime.

;(in-ns 'org.enrico_franchi.paip.simplegrammar.grammar)

; I believe that this should make clojure.core functions not accessible; however, I have the habit of importing
; the "core" libraries (at least, I did that in common lisp packages, as recommended).
; Consequently my namespace declaration is, for example:

;(ns org.enrico_franchi.paip.simplegrammar.grammar
;  (:use
;   clojure.core
;   clojure.contrib.combinatorics))

; And slime is in my namespace, so I can use the functions as I want (user is not modified) and I can also call
; clojure.core and whatever I need.





;(put 'upcase-region 'disabled nil)
	 
;	(add-to-list 'load-path "/home/stephen/opt/clojure/clojure-mode")
;	(require 'clojure-mode)
;	(add-to-list 'load-path "/home/stephen/opt/clojure/swank-clojure")
;	(require 'swank-clojure)
;	(add-hook 'clojure-mode-hook
;	          '(lambda ()
;	             (define-key clojure-mode-map "\C-c\C-e" 'lisp-eval-last-sexp)
;	             (define-key clojure-mode-map "\C-x\C-e" 'lisp-eval-last-sexp)))
;	(eval-after-load "slime"
;	  `(progn
;	     (require 'assoc)
;	     (setq swank-clojure-classpath
;	           (list "/home/stephen/opt/clojure/clojure/clojure.jar"
;	                 "/home/stephen/opt/clojure/clojure-contrib/clojure-contrib.jar"
;	                 "/home/stephen/opt/clojure/swank-clojure/src"))
;	     (aput 'slime-lisp-implementations 'clojure
;	           (list (swank-clojure-cmd) :init 'swank-clojure-init))))
