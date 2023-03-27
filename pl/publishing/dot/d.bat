@echo off
setlocal

set GRAPHVIS_HOME=D:\dev\Utils\Graphviz2_24

%GRAPHVIS_HOME%\Bin\dot.exe full.dot -Tpng -o full.png
rem %GRAPHVIS_HOME%\Bin\dot.exe short.dot -Tpng -o short.png

endlocal