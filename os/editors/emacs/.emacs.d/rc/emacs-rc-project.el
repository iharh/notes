(add-to-list 'load-path "~/.emacs.d/site-lisp/mk-project")
(require 'mk-project)

(project-def "my-clojure-project"
	'(
		(basedir          "D:/dev/Clojure/prj/myprj/")
		(src-patterns     ("*.clj")) ; "*.java"
		(ignore-patterns  ("*.class" "*.jar" ".*")) ; "*.wsdl"
		(tags-file        "D:/dev/Clojure/prj/myprj/.TAGS") ; TAGS
		(file-list-cache  "D:/dev/Clojure/prj/myprj/.files")
		(open-files-cache "D:/dev/Clojure/prj/myprj/.open-files")
;		(vcs              git)
;		(compile-cmd      "ant")
;		(ack-args         "--java")
;		(startup-hook     my-clojure-project-startup) ; maybe use lambda here ?
;		(shutdown-hook    nil)
	)
)

;(defun my-clojure-project-startup ()
;	(setq c-basic-offset 3)
;)

(project-def "tc-jmx-clj"
	'(
		(basedir          "D:/dev/Clojure/prj/tc-jmx/")
		(src-patterns     ("*.clj")) ; "*.java"
		(ignore-patterns  ("*.class" "*.jar" ".*")) ; "*.wsdl"
		(tags-file        "D:/dev/Clojure/prj/tc-jmx/.TAGS") ; TAGS
		(file-list-cache  "D:/dev/Clojure/prj/tc-jmx/.files")
		(open-files-cache "D:/dev/Clojure/prj/tc-jmx/.open-files")
;		(vcs              git)
;		(compile-cmd      "ant")
;		(ack-args         "--java")
;		(startup-hook     tc-jmx-clj-project-startup) ; maybe use lambda here ?
;		(shutdown-hook    nil)
	)
)
