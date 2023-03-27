;;(setq font-lock-maximum-decoration
;;      '((c-mode . 1) (c++-mode . 2)))

(make-face 'font-lock-operator-face)
(make-face 'font-lock-end-statement)
(make-face 'font-lock-digit)

(setq font-lock-operator-face 'font-lock-operator-face)
(setq font-lock-end-statement 'font-lock-end-statement)
(setq font-lock-digit         'font-lock-digit)

;; Enhanced syntax highlighting 
;; Currently support for []|&!.+=-/%*,()<>{}


;; if the second argument of (cons ...) is not a list - a dotted pair is created : (cons 1 2) -> (1 . 2)

;; (type-of "testing") -> string

;; (regexp-opt '( "v1" "v2")) -> \(?:v1\|v2\) 
;;    \(?: ... \) - is the shy group construct. 

(font-lock-add-keywords
	'c++-mode
;;	'(
;;		("\\(\\[\\|\\]\\|[|!\\.\\+\\=\\&]\\|-\\|\\/\\|\\%\\|\\*\\|,\\|(\\|)\\|>\\ |<\\|{\\|}\\)" 1 font-lock-operator-face)
;;		("\\(;\\)" 1 font-lock-end-statement)
;;	)
	(list
		;; todo: float numbers should be green - \\(\\.?\\)
		;;(cons "\\b[[:digit:]]+\\(\\.[[:digit:]]+\\)?" 'font-lock-digit)
		(cons
			;; "\\b[[:digit:]]+"
			(rx
				(or
					(and
						word-boundary ;; \\b
						(+ digit) ;; one-or-more
						(\? ;; zero-or-one
							"."
						)
						(+ digit)
						(\? ;; zero-or-one
							(in "eE")
							(\? (in "+-"))
							(+ digit)
						)
					)
					(and
						word-boundary ;; \\b
						(+ digit) ;; one-or-more
					)
				)
			)
			'font-lock-digit
		)
		;; (rx (one-or-more digit))
		;; bow - instead of word-boundary
		(cons
			(regexp-opt '(
				":" "," "." "+" "-" "=" "&" "|" "!" "%"
				"[" "]" "(" ")" "<" ">"
			)
		) 'font-lock-operator-face)
		;; ; { } should be ellow
		(cons (regexp-opt '(";" "{" "}")) 'font-lock-end-statement)
	)
	'to-end
)


(font-lock-add-keywords
	'emacs-lisp-mode
;;	'(
;;		("\\(\\[\\|\\]\\|[|!\\.\\+\\=\\&]\\|-\\|\\/\\|\\%\\|\\*\\|,\\|(\\|)\\|>\\ |<\\|{\\|}\\)" 1 font-lock-operator-face)
;;		("\\(;\\)" 1 font-lock-end-statement)
;;	)
	(list
		(cons
			(regexp-opt '(
				"(" ")"
			)
		) 'font-lock-operator-face)
	)
	'to-end
)

;;(setq c-operators-regexp
;;	(regexp-opt
;;		'(
;;			"+" "-" "*" "/" "%" "!"
;;			"&" "^" "~" "|"
;;			"=" "<" ">"
;;			"." "," ";" ":"
;;		)
;;	)
;;)

;;(setq c-brackets-regexp
;;	(regexp-opt
;;		'( "(" ")" "[" "]" "{" "}" )
;;	)
;;)
