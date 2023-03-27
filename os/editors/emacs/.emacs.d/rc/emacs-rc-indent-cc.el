(setq c-tab-always-indent nil)

(c-add-style "iharh-personal-cc-style"
	'(
		;;"bsd" ;; no parent
		(c-echo-syntactic-information-p . t) ;; comment this out after stabilizing settings
		(c-basic-offset . 8)
		;;(c-comment-only-line-offset . (0 . 0))
		(c-offsets-alist . ;; can be also set via  (c-set-offset 'arglist-intro '+) 
			(
				(innamespace           . 0) ;; - ?? [4]
				;;(inline-open           . 0)
				;;(inher-cont            . c-lineup-multi-inher)
				;;(arglist-cont-nonempty . +)
				;;(template-args-cont    . +)
				;;(c                     . c-lineup-C-comments)
				;;(statement-case-open   . 0)
				;;(case-label            . +)
				;;(substatement-open     . 0)
			)
		)
	)
)

;; cc-mode-common-hook - c-mode-hook don't work - try c++-mode-hook also
(add-hook 'c-mode-common-hook
	(lambda ()
		(c-set-style "iharh-personal-cc-style")
	)
)
