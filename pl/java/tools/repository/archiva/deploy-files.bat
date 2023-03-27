@echo off
setlocal

set OPT_REPO=-Durl=http://epbygomsd0006:8001/archiva/repository/internal -DrepositoryId=archiva.internal

call:doDeploy jclark xt 20020426a
call:doDeploy net.sourceforge.cpdetector cpdetector 1.0.5
call:doDeploy com.oracle ojdbc5 11.1.0.7.0
call:doDeploy com.sun.jmx jmxri 1.2.1
call:doDeploy com.sun.jdmk jmxtools 1.2.1

goto:eof


:doDeploy

set groupId=%~1
set groupPath=%groupId:.=/%
set artifactId=%~2
set version=%~3
set filePath=./%groupPath%/%artifactId%/%version%/%artifactId%-%version%.jar

echo deploying ... %groupId%:%artifactId%:%version%

echo groupId=%groupId%

set OPTS=-DgroupId=%groupId% -DartifactId=%artifactId% -Dversion=%version% -Dpackaging=jar -Dfile=%filePath% %OPT_REPO%
::echo OPTS=%OPTS%

call mvn.bat deploy:deploy-file %OPTS%
:: -e

goto:eof

endlocal
