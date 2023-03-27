@echo off

rem ---------------------------------------------------------------------------
rem Startup Script for Insight
rem
rem Environment Variable Prequisites
rem
rem   JAVA_HOME      Must point to a valid Java 2 JRE or JDK directory with 
rem                  version 1.4.2 or later.
rem
rem   INSIGHT_HOME   Must point to the directory where this application was 
rem                  extracted to.
rem $Id: insight.bat 36 2007-12-16 15:34:09Z bindul $
rem ---------------------------------------------------------------------------

rem  
rem   Copyright (c) 2005 MindTree Consulting Ltd.
rem   
rem   This file is part of Insight.
rem   
rem   Insight is free software: you can redistribute it 
rem   and/or modify it under the terms of the GNU General Public License as 
rem   published by the Free Software Foundation, either version 3 of the License, 
rem   or (at your option) any later version.
rem   
rem   Insight is distributed in the hope that it will be 
rem   useful, but WITHOUT ANY WARRANTY; without even the implied warranty of 
rem   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General 
rem   Public License for more details.
rem   
rem   You should have received a copy of the GNU General Public License along with 
rem   Insight.  If not, see <http://www.gnu.org/licenses/>.
rem  

:initLocal
if "%OS%"=="Windows_NT" @setlocal
if "%OS%"=="WINNT" @setlocal

:checkJavaHome
@REM ==== START VALIDATION ====
if not "%JAVA_HOME%" == "" goto OkJHome

echo.
echo ERROR: JAVA_HOME not found in your environment.
echo Please set the JAVA_HOME variable in your environment to match the
echo location of your Java installation
echo.
goto error

:OkJHome
if exist "%JAVA_HOME%\bin\java.exe" goto inferInsightHome
goto end

:inferInsightHome
rem --------- use the location of this script to infer INSIGHT_HOME ------------
if NOT "%OS%"=="Windows_NT" set DEFAULT_INSIGHT_HOME=.
if "%OS%"=="Windows_NT" set DEFAULT_INSIGHT_HOME=%~dp0
if "%OS%"=="WINNT" set DEFAULT_INSIGHT_HOME=%~dp0
if "%INSIGHT_HOME%"=="" set INSIGHT_HOME=%DEFAULT_INSIGHT_HOME%
goto checkInsightHome

:checkInsightHome
if not "%INSIGHT_HOME%" == "" goto gotInsightHome
echo The INSIGHT_HOME environment variable has not been defined
goto end

:gotInsightHome
if exist "%INSIGHT_HOME%\config\insight-preferences.xml" goto setClasspath
echo The INSIGHT_HOME environment variable is not defined correctly
echo This environment variable is needed to run this program. Please set it to the folder where Insight archive was extracted
goto end


:setClasspath
set INSIGHT_JAR=insight-ui-1.5.2.jar
rem ${project.artifactId}-${project.version}.jar
set INSIGHT_CLASS_PATH=.;%INSIGHT_JAR%;%INSIGHT_HOME%\bin
set TEMP_CP_FILE=%TEMP%\Insight-cp-temp.bat

If %OS%'==Windows_NT' Set NTSwitch=/F "Tokens=*"
If %OS%'==WINNT' Set NTSwitch=/F "Tokens=*"

if exist "%TEMP_CP_FILE%" del /f %TEMP_CP_FILE%
for %NTSwitch% %%i in ('dir %INSIGHT_HOME%\lib\*.jar /b') do echo set INSIGHT_CLASS_PATH=%%INSIGHT_CLASS_PATH%%;%INSIGHT_HOME%\lib\%%i>>%TEMP_CP_FILE%
call %TEMP_CP_FILE%
del /f %TEMP_CP_FILE%


set INSIGHT_OPTIONS=-DINSIGHT_HOME=%INSIGHT_HOME%
set INSIGHT_CLASS=com.mindtree.techworks.insight.Insight

set JIP_OPTIONS=-javaagent:%JIP_HOME%\profile\profile.jar -Dprofile.properties=%JIP_HOME%\profile\insight-ui.timeline.properties -Xmx1200m

%JAVA_HOME%\bin\java -cp %INSIGHT_CLASS_PATH% %INSIGHT_OPTIONS% %JIP_OPTIONS% %INSIGHT_CLASS% %1 %2 %3 %4 %5 %6 %7 %8 %9

:end
if "%OS%"=="Windows_NT" @endlocal
if "%OS%"=="WINNT" @endlocal
