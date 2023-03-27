@echo off
setlocal

if defined PROCESSOR_ARCHITEW6432 (set reg="%systemroot%\sysnative\reg.exe") else (set reg=reg)

set werfile-suff=WER.reg

set savepath=%~dp0

:: hkcu, hklm
call :save "hklm\SOFTWARE\Microsoft\Windows\Windows Error Reporting" "%savepath%%COMPUTERNAME%-%werfile-suff%"

goto :eof

:save
:: >nul 2>^&1
%reg% query %1
if not errorlevel 1 (
if exist %2 (
echo.
echo Deleting %2...
del /f %2
)
echo.
echo Exporting %1...
%reg% export %1 %2
)

endlocal

