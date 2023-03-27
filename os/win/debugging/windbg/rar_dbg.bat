@echo off
setlocal

cd %KANISA_HOME%\Server

set LOG4CXX_CONFIGFILE=%KANISA_HOME%\Server\log4jConfig\log4cxx_IRAR.properties
set KANISA_ADMIN=%KANISA_HOME%\Server\nsadmin.xml
set KANISA_CONFIGFILE=%KANISA_HOME%\Kanisa-Build-1223363670\config.xml
set JAVA_OPTS=-Xbootclasspath/p:"%TC_INSTALL_DIR%\lib\dso-boot\dso-boot-hotspot_win32_160_07.jar" -Dtc.install-root="%TC_INSTALL_DIR%" -Dtc.config=Terracotta\tc-config.xml -Xmx256m -Dcom.tc.loader.system.name=Tomcat.shared -Dtc.node-name=KRARServer -Djava.class.path=dove.jar;ConfigData.jar;jace-1.0-SNAPSHOT.jar;lib\log4j-1.2.15.jar;rar-1.0-SNAPSHOT.jar;lib\antlr-2.7.6.jar;lib\aopalliance-1.0.jar;lib\asm-1.5.3.jar;lib\asm-attrs-1.5.3.jar;lib\aspectjrt-1.6.0.jar;lib\aspectjweaver-1.6.0.jar;lib\cglib-2.1_3.jar;lib\commons-collections-2.1.1.jar;lib\commons-logging-1.1.1.jar;lib\dom4j-1.6.1.jar;lib\ehcache-1.2.3.jar;lib\hibernate-3.2.6.ga.jar;lib\jta-1.0.1B.jar;lib\jtds-1.2.2.jar;lib\ojdbc5.jar;lib\junit-4.4.jar;lib\spring-aop-2.5.5.jar;lib\spring-aspects-2.5.5.jar;lib\spring-beans-2.5.5.jar;lib\spring-context-2.5.5.jar;lib\spring-core-2.5.5.jar;lib\spring-jdbc-2.5.5.jar;lib\spring-orm-2.5.5.jar;lib\spring-tx-2.5.5.jar -DKANISA_CONFIGFILE="nsadmin.xml"

"D:\dev\Utils\Debugging Tools for Windows (x86)\windbg.exe" -WRio-RARServer
rem -i%KANISA_HOME%\Server
rem KRARServer.exe

rem -g ignore initial break
rem -G ignore final break
rem -i executable image path
rem -v verbose

rem jnial::JNILibInitializer::m_Instance.m_pType->m_JNILibraryPtr.m_pType->m_JavaVM

rem .step_filter "FilterList" 
rem .step_filter /c 
rem .step_filter 

rem k - simple stack trace of current process
rem kM - in DML

endlocal
