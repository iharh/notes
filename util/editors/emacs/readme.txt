C-x C-c
	Kill Emacs (save-buffers-kill-terminal).
M-`
F10
	Enter menu. M-` (a back quote, the single open quotation mark, located above the Tab key in the upper-left
	corner of many keyboards).

Menu
	C-<right mouse> to open global menu



Buffers

C-x b
	Buffer list (Visit buffer)
C-x C-b
	Buffer list (in a new window)
C-x ->
	Go to next buffer
C-x <-
	Go to prev buffer
C-x k
	Kill the buffer
M-x kill-some-buffers
	Kill buffers interactively



Buffer (editing)

C-/ (C-_)
C-x u
	Undo
C-x C-f
	Open a file (open "Find File" prompt)
C-x C-v
	Open another file (instead of this one)
C-x C-s
	Save the file
C-x C-w
	Save the file as (write-file)
C-x s
	Save some buffers (save-some-buffers)
M-x rename-buffer
	Rename buffer
C-x C-q
	Make buffer readonly
C-x f
	Visit recent file
C-x p
	Visit a file under a cursor
C-c r
	Revert to file on disk


Copy/Past (Kill/Yank)
C-" " (or C-@)
	Set the mark (Ctrl+Space), G-g - to undo marking
C-w
	Kill (cut) region (kill-region)
M-w
	Copy region (kill-ring-save)
C-k
	Kill all the text up to the end of the line
C-M-h
	Kill previous word
C-y
	Yank (yank)
M-y
	(yank-pop)







C-u C-" "
	Jump to last mark

Completion mode:
C-y
	Send buffer to end of list



Basic Movement

-- FORWARD
C-f
	one character
M-f
	one word
C-e
	end of the line

-- BACKWARD
C-b
	one character
M-b
	one word
C-a
	beginning of the line

-- NEXT
C-n
	next line (next-line)

-- PREVIOUS
C-p
	previous line

-- DOWN
C-v
	page down

- UP
M-v
	page up

-- BEGINNING
M-"<-"
	beginning of the document

-- END (BOTTOM)
M-"->"
	end (bottom) of the document

-- MIDDLE
C-l
	cursor to the middle of the screen

Search

C-s
	incremental search
	C-s again - move to the next occurence
	C-r       - previous occurence
	RET       - move to the cursor, exit the search mode
	C-g       - cancel the search











Minibuffer (Keyboard)

C-g
	Break current command



Code Browsing

C-x C-i
	Functions list
M-.
	Jump to implementation





Major Modes

auto-mode-alist
	list of ext-to-mode associations (C-h v ...)
M-x ruby-mode
	manually switch the mode


Minor Modes

C-c n
	Cleanup whitespaces



Version Control

C-x v
	Diff against HEAD
C-x v u
	Discard changes
C-x v l
	View commit log


Shell interaction

M-x shell-command
	execute shell command

Eshell

M-x eshell
	eshell (lisp\eshell\eshell.el)
