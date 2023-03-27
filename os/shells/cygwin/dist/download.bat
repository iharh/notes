@echo off
setlocal

set CYG_FTP=ftp://mirrors.kernel.org/sourceware/cygwin
set CYG_DIST_DIR=%~d0%~p0
set CYG_PACKAGES=cygwin,man,coreutils,gettext,mintty,rxvt,zsh,make

setup.exe -qDOs %CYG_FTP% -l %CYG_DIST_DIR% -P %CYG_PACKAGES% 

:: Install state is stored at - C:\cygwin\etc\setup

endlocal
