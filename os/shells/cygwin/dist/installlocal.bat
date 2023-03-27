@echo off
setlocal

set CYG_ROOT=C:\cygwin
set CYG_DIST_DIR=%~d0%~p0
set CYG_PACKAGES=cygwin,man,coreutils,gettext,mintty,rxvt,zsh,make

setup.exe -qLNn -l %CYG_DIST_DIR% -R %CYG_ROOT% -P %CYG_PACKAGES% 

endlocal

