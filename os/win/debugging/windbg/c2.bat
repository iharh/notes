@echo off
if _%1==_ exit /B
rem echo %1

cdb -p %1 -pv -logo c2.txt -cf c2.ccd -y "D:\Knova\Geneva\7.22\inst\Platform\Server;SRV*D:\dev\MsSymbols*http://msdl.microsoft.com/download/symbols"

rem -pv specifies that any attach should be noninvasive
rem -v enables verbose output from debugger
