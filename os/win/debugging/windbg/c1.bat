@echo off
if _%1==_ exit /B
rem echo %1

cdb -p %1 -pv -logo c1.txt -y "D:\Knova\Geneva\7.22\inst\Platform\Server" -c "!sym prompts;.reload /f;qd"
