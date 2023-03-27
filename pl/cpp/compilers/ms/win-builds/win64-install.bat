@echo off

set OLD_PATH=%PATH%

set _YY_BITS=64
set _YY_ARCH=x86_64

set YYPREFIX=D:/win-builds-%_YY_BITS%
set PATH=%YYPREFIX%/bin;%OLD_PATH%

echo ***************************************************
echo Installing win-builds for %_YY_ARCH% in %YYPREFIX%.
echo ***************************************************

yypkg -init
yypkg -config -setpreds host=%_YY_ARCH%-w64-mingw32
yypkg -config -setpreds target=%_YY_ARCH%-w64-mingw32
sherpa -set-mirror http://win-builds.org/1.3.0/packages/windows_%_YY_BITS%
echo Downloading and installing packages.
sherpa -install all

echo Updating fontconfig's cache (takes lot of time and memory on Windows 7/8).
fc-cache

echo Updating pango's module cache.
REM Pango doesn't respect --libdir for the module cache so simply update the
REM list in /etc (for now).
pango-querymodules > %YYPREFIX%/etc/pango/pango.modules

::copy *.exe "%YYPREFIX%/bin"
::copy *.dll "%YYPREFIX%/bin"

echo Win-builds has been installed.
echo System settings like PATH haven't been changed; you should do so now.

pause
