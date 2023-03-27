REM Script for exporting schema & data for an oracle user

set NLS_LANG=American_America.AL32UTF8
set NLS_CHARACTERSET=AL32UTF8
set NLS_NCHAR_CHARACTERSET=AL16UTF16

for /f "tokens=1-4 delims=/ "  %%d in ("%date%") do set text1=%%g%%e%%f

for /f "tokens=1-4 delims=:. " %%d in ("%time%") do set text2=%%d%%e%%f%
set suffix=%text1%_%text2%

REM echo %suffix%
date /t >  export.log
time /t >> export.log

exp admkanisa/admkanisa@kckgs101 file=admkanisa_%suffix%.dmp buffer=1048576 log=kadmin_%suffix%.log

date /t >> export.log
time /t >> export.log
