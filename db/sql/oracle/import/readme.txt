REM Script for exporting schema & data for an oracle user

set NLS_LANG=American_America.AL32UTF8
set NLS_CHARACTERSET=AL32UTF8
set NLS_NCHAR_CHARACTERSET=AL16UTF16

REM - change the value of kadmin_xxxxxxxx.dmp to the correct name of the file from which it should be imported.
REM - if you import on top of existing database, the rows will get added
REM So have an empty schema before importing.

date /t >  import.log
time /t >> import.log

imp system/oracle123@KCKGS101 file=admkanisa3_20090712_154015.dmp buffer=1048576 fromuser=admkanisa3 touser=admkanisa log=admkanisa-import.log

date /t >> import.log
time /t >> import.log
