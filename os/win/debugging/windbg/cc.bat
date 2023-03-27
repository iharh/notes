@echo off
if _%1==_ exit /B
rem echo %1

cdb -p %1 -pv -logo cc.log -y "SRV*C:\MSSymbols*http://msdl.microsoft.com/download/symbols"

rem -pv specifies that any attach should be noninvasive
rem -v enables verbose output from debugger
