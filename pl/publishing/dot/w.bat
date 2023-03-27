@echo off
setlocal

call %VSCOMNTOOLS%vsvars32.bat

dumpbin -dependents %1

endlocal
