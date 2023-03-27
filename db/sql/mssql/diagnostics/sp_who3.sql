 /* In addition, a @hostname parameter is added which allows the user the option of viewing activity originating from only one computer, if desired. */

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO


CREATE   PROCEDURE sp_who3
    @loginame     sysname = NULL,
    /* NEW PARAMETER ADDED BY CHB */
    @hostname     sysname = NULL			
as

set nocount on

if @hostname is null set @hostname = '0'

declare
    @retcode         int

declare
    @sidlow         varbinary(85)
   ,@sidhigh        varbinary(85)
   ,@sid1           varbinary(85)
   ,@spidlow         int
   ,@spidhigh        int

declare
    @charMaxLenLoginName      varchar(6)
   ,@charMaxLenDBName         varchar(6)
   ,@charMaxLenCPUTime        varchar(10)
   ,@charMaxLenDiskIO         varchar(10)
   ,@charMaxLenHostName       varchar(10)
   ,@charMaxLenProgramName    varchar(10)
   ,@charMaxLenLastBatch      varchar(10)
   ,@charMaxLenCommand        varchar(10)

declare
    @charsidlow              varchar(85)
   ,@charsidhigh             varchar(85)
   ,@charspidlow              varchar(11)
   ,@charspidhigh             varchar(11)

--------

select
    @retcode         = 0      -- 0=good ,1=bad.

--------defaults
select @sidlow = convert(varbinary(85), (replicate(char(0), 85)))
select @sidhigh = convert(varbinary(85), (replicate(char(1), 85)))

select
    @spidlow         = 0
   ,@spidhigh        = 32767

--------------------------------------------------------------
IF (@loginame IS     NULL)  --Simple default to all LoginNames.
      GOTO LABEL_17PARM1EDITED

--------

-- select @sid1 = suser_sid(@loginame)
select @sid1 = null
if exists(select * from master.dbo.syslogins where loginname = @loginame)
	select @sid1 = sid from master.dbo.syslogins where loginname = @loginame

IF (@sid1 IS NOT NULL)  --Parm is a recognized login name.
   begin
   select @sidlow  = suser_sid(@loginame)
         ,@sidhigh = suser_sid(@loginame)
   GOTO LABEL_17PARM1EDITED
   end

--------

IF (lower(@loginame) IN ('active'))  --Special action, not sleeping.
   begin
   select @loginame = lower(@loginame)
   GOTO LABEL_17PARM1EDITED
   end

--------

IF (patindex ('%[^0-9]%' , isnull(@loginame,'z')) = 0)  --Is a number.
   begin
   select
             @spidlow   = convert(int, @loginame)
            ,@spidhigh  = convert(int, @loginame)
   GOTO LABEL_17PARM1EDITED
   end

--------

RaisError(15007,-1,-1,@loginame)
select @retcode = 1
GOTO LABEL_86RETURN


LABEL_17PARM1EDITED:


--------------------  Capture consistent sysprocesses.  -------------------

SELECT

  spid
 ,CAST(null AS VARCHAR(5000)) as commandtext
 ,status
 ,sid
 ,hostname
 ,program_name
 ,cmd
 ,cpu
 ,physical_io
 ,blocked
 ,dbid
 ,convert(sysname, rtrim(loginame))
        as loginname
 ,spid as 'spid_sort'

 ,  substring( convert(varchar,last_batch,111) ,6  ,5 ) + ' '
  + substring( convert(varchar,last_batch,113) ,13 ,8 )
       as 'last_batch_char'

      INTO    #tb1_sysprocesses
      from master.dbo.sysprocesses   (nolock)

/*******************************************

FOLLOWING SECTION ADDED BY CHB 05/06/2004

RETURNS LAST COMMAND EXECUTED BY EACH SPID

********************************************/

CREATE TABLE #spid_cmds
(SQLID INT IDENTITY, spid INT, EventType VARCHAR(100), Parameters INT, Command VARCHAR(5000))

DECLARE spids CURSOR FOR
SELECT spid FROM #tb1_sysprocesses

DECLARE @spid INT, @sqlid INT

OPEN spids
FETCH NEXT FROM spids 
INTO @spid

/*
EXECUTE DBCC INPUTBUFFER FOR EACH SPID
*/

WHILE (@@FETCH_STATUS = 0)
BEGIN
	
	INSERT INTO #spid_cmds (EventType, Parameters, Command)
	EXEC('DBCC INPUTBUFFER( ' + @spid + ')')

	SELECT @sqlid = MAX(SQLID) FROM #spid_cmds

	UPDATE #spid_cmds SET spid = @spid WHERE SQLID = @sqlid 	

	FETCH NEXT FROM spids INTO @spid

END

CLOSE spids
DEALLOCATE spids

UPDATE p
SET p.commandtext = s.command
FROM #tb1_sysprocesses P
JOIN #spid_cmds s
ON p.spid = s.spid

---------------------------------------------

--------Screen out any rows?

IF (@loginame IN ('active'))
   DELETE #tb1_sysprocesses
         where   lower(status)  = 'sleeping'
         and     upper(cmd)    IN (
                     'AWAITING COMMAND'
                    ,'MIRROR HANDLER'
                    ,'LAZY WRITER'
                    ,'CHECKPOINT SLEEP'
                    ,'RA MANAGER'
                                  )

         and     blocked       = 0



--------Prepare to dynamically optimize column widths.


Select
    @charsidlow     = convert(varchar(85),@sidlow)
   ,@charsidhigh    = convert(varchar(85),@sidhigh)
   ,@charspidlow     = convert(varchar,@spidlow)
   ,@charspidhigh    = convert(varchar,@spidhigh)



SELECT
             @charMaxLenLoginName =
                  convert( varchar
                          ,isnull( max( datalength(loginname)) ,5)
                         )

            ,@charMaxLenDBName    =
                  convert( varchar
                          ,isnull( max( datalength( rtrim(convert(varchar(128),db_name(dbid))))) ,6)
                         )

            ,@charMaxLenCPUTime   =
                  convert( varchar
                          ,isnull( max( datalength( rtrim(convert(varchar(128),cpu)))) ,7)
                         )

            ,@charMaxLenDiskIO    =
                  convert( varchar
                          ,isnull( max( datalength( rtrim(convert(varchar(128),physical_io)))) ,6)
                         )

            ,@charMaxLenCommand  =
                  convert( varchar
                          ,isnull( max( datalength( rtrim(convert(varchar(128),cmd)))) ,7)
                         )

            ,@charMaxLenHostName  =
                  convert( varchar
                          ,isnull( max( datalength( rtrim(convert(varchar(128),hostname)))) ,8)
                         )

            ,@charMaxLenProgramName =
                  convert( varchar
                          ,isnull( max( datalength( rtrim(convert(varchar(128),program_name)))) ,11)
                         )

            ,@charMaxLenLastBatch =
                  convert( varchar
                          ,isnull( max( datalength( rtrim(convert(varchar(128),last_batch_char)))) ,9)
                         )
      from
             #tb1_sysprocesses
      where
--             sid >= @sidlow
--      and    sid <= @sidhigh
--      and
             spid >= @spidlow
      and    spid <= @spidhigh



--------Output the report.


EXECUTE(
'
SET nocount off

SELECT
             SPID          = convert(char(5),spid)
	     ,CommandText	

            ,Status        =
                  CASE lower(status)
                     When ''sleeping'' Then lower(status)
                     Else                   upper(status)
                  END

            ,Login         = substring(loginname,1,' + @charMaxLenLoginName + ')

            ,HostName      =
                  CASE hostname
                     When Null  Then ''  .''
                     When '' '' Then ''  .''
                     Else    substring(hostname,1,' + @charMaxLenHostName + ')
                  END

            ,BlkBy         =
                  CASE               isnull(convert(char(5),blocked),''0'')
                     When ''0'' Then ''  .''
                     Else            isnull(convert(char(5),blocked),''0'')
                  END

            ,DBName        = substring(case when dbid = 0 then null when dbid <> 0 then db_name(dbid) end,1,' + @charMaxLenDBName + ')
            ,Command       = substring(cmd,1,' + @charMaxLenCommand + ')

            ,CPUTime       = substring(convert(varchar,cpu),1,' + @charMaxLenCPUTime + ')
            ,DiskIO        = substring(convert(varchar,physical_io),1,' + @charMaxLenDiskIO + ')

            ,LastBatch     = substring(last_batch_char,1,' + @charMaxLenLastBatch + ')

            ,ProgramName   = substring(program_name,1,' + @charMaxLenProgramName + ')
            ,SPID          = convert(char(5),spid)  --Handy extra for right-scrolling users.
      from
             #tb1_sysprocesses  --Usually DB qualification is needed in exec().
      where
             spid >= ' + @charspidlow  + '
      and    spid <= ' + @charspidhigh + '
      and    (HostName like ''' + @hostname + '%'' or ''' + @hostname + ''' = ''0'')

      -- (Seems always auto sorted.)   order by spid_sort

SET nocount on
'
)
/*****AKUNDONE: removed from where-clause in above EXEC sqlstr
             sid >= ' + @charsidlow  + '
      and    sid <= ' + @charsidhigh + '
      and
**************/


LABEL_86RETURN:


if (object_id('tempdb..#tb1_sysprocesses') is not null)
            drop table #tb1_sysprocesses

return @retcode -- sp_who2



GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO 
