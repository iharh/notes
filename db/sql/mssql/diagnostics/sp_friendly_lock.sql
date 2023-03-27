                 
CREATE PROC sp_friendly_lock 
AS 
SET NOCOUNT ON 
DECLARE @dbid varchar(20), 
        @dbname sysname, 
        @objname sysname, 
        @objid int, 
        @execstr varchar(8000), 
        @nexecstr nvarchar(4000) 

CREATE TABLE #locks (spid int, 
                     dbid int, 
                     objid int, objectname sysname NULL, 
                     indid int, 
                     type char(4), 
                     resource char(15), 
                     mode char(10), 
                     status char(6)) 

-- Get basic locking info from sp_lock 
INSERT #locks (spid, dbid, objid, indid, type, resource, mode, status) EXEC sp_lock 

-- Loop through the work table and translate each object id into an object name 
DECLARE DBs CURSOR FOR SELECT DISTINCT dbid=CAST(dbid AS varchar) FROM #locks 
OPEN DBs 
FETCH DBs INTO @dbid 
WHILE (@@FETCH_STATUS=0) BEGIN 
        SET @dbname=DB_NAME(@dbid) 
        EXEC master..xp_sprintf @execstr OUTPUT,'UPDATE #locks 
        SET objectname=o.name FROM %s..sysobjects o 
        WHERE (#locks.type=''TAB'' OR #locks.type=''PAG'') 
        AND dbid=%s AND #locks.objid=o.id',@dbname, @dbid

        EXEC(@execstr) 
        EXEC master..xp_sprintf @execstr OUTPUT, 'UPDATE #locks 
        SET objectname=i.name FROM %s..sysindexes i 
        WHERE (#locks.type=''IDX'' OR #locks.type=''KEY'') 
        AND dbid=%s AND #locks.objid=i.id 
        AND #locks.indid=i.indid', @dbname, @dbid

        EXEC(@execstr) 
        EXEC master..xp_sprintf @execstr OUTPUT, 'UPDATE #locks 
        SET objectname=f.name FROM %s..sysfiles f WHERE #locks.type=''FIL'' 
        AND dbid=%s AND #locks.objid=f.fileid', @dbname, @dbid

        EXEC(@execstr) 
        FETCH DBs INTO @dbid 
END 
CLOSE DBs 
DEALLOCATE DBs 

-- Return the result set 
SELECT login=LEFT(p.loginame,20), db=LEFT(DB_NAME(l.dbid),30), l.type, object=CASE 
   WHEN l.type='DB' 
   THEN LEFT(DB_NAME(l.dbid),30) 
   ELSE LEFT(objectname,30) END, l.resource, l.mode, l.status, l.objid, l.indid, l.spid

   FROM #locks l JOIN sysprocesses p ON (l.spid=p.spid) 
   ORDER BY 1,2,3,4,5,6,7 

DROP TABLE #locks 

RETURN 0 
go 