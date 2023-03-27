-- select * from sys.dm_os_waiting_tasks where blocking_session_id is not null
SELECT
	tl.request_session_id,
	wt.blocking_session_id,
	tl.resource_database_id,
	DB_NAME(tl.resource_database_id) AS DatabaseName,
	tl.resource_type,
	tl.request_mode,
	tl.resource_associated_entity_id
FROM
	sys.dm_tran_locks as tl
INNER JOIN
	sys.dm_os_waiting_tasks as wt
ON
	tl.lock_owner_address = wt.resource_address
order by
	tl.request_session_id;
