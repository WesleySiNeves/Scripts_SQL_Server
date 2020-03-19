/*########################
# OBS: Enable collection of execution statistics for natively compiled
*/


/*########################
# OBS: sys.sp_xtp_control_proc_exec_stats Use este procedimento armazenado do sistema para ativar
coleção de estatísticas para sua instância do SQL Server no nível de procedimento.	
*/


/*########################
# OBS: Enable and disable statistics collection at the procedure level
*/

--Enable statistics collection at the procedure level
EXEC sys.sp_xtp_control_proc_exec_stats @new_collection_value = 1;


--Check the current status of procedure-level statistics collection
DECLARE @c BIT;
EXEC sys.sp_xtp_control_proc_exec_stats @old_collection_value = @c OUTPUT;
SELECT @c AS 'Current collection status';


--Disable statistics collection at the procedure level
EXEC sys.sp_xtp_control_proc_exec_stats @new_collection_value =
0;



/*########################
# OBS: 2) sys.sp_xtp_control_query_exec_stats
Enable and disable statistics collection at the query level
*/
EXEC sys.sp_xtp_control_query_exec_stats @new_collection_value = 1;


--Check the current status of query-level statistics collection
DECLARE @c BIT;
EXEC sys.sp_xtp_control_query_exec_stats @old_collection_value = @c OUTPUT;
SELECT @c AS 'Current collection status';
--Disable statistics collection at the query level
EXEC sys.sp_xtp_control_query_exec_stats @new_collection_value = 0;



/*########################
# OBS: 3)
--Enable statistics collection at the query level for a
specific
--natively compiled stored procedure
*/

DECLARE @ncspid int;
DECLARE @dbid int;
SET @ncspid = OBJECT_ID(N'Examples.OrderInsert_NC');
SET @dbid = DB_ID(N'ExamBook762Ch3_IMOLTP')
EXEC [sys].[sp_xtp_control_query_exec_stats]
@new_collection_value = 1,
@database_id = @dbid, @xtp_object_id = @ncspid;




/*########################
# OBS: Depois de ativar as coleções de estatísticas no nível de procedimento, você pode consultar
sys.dm_exec_procedure_stats DMV para revisar os resultados. A Listagem 3-19 ilustra um
consulta de exemplo que filtra para procedimentos armazenados compilados nativamente. Esta consulta retorna
*/
SELECT OBJECT_NAME(PS.object_id) AS obj_name,
       cached_time AS cached_tm,
       last_execution_time AS last_exec_tm,
       execution_count AS ex_cnt,
       total_worker_time AS wrkr_tm,
       total_elapsed_time AS elpsd_tm
FROM sys.dm_exec_procedure_stats PS
    INNER JOIN sys.all_sql_modules SM
        ON SM.object_id = PS.object_id
WHERE SM.uses_native_compilation = 1;


/*########################
# OBS: Get query-level statistics
*/
SELECT st.objectid AS obj_id,
       OBJECT_NAME(st.objectid) AS obj_nm,
       SUBSTRING(
                    st.text,
                    (QS.statement_start_offset / 2) + 1,
                    ((QS.statement_end_offset - QS.statement_start_offset) / 2) + 1
                ) AS 'Query',
       QS.last_execution_time AS last_exec_tm,
       QS.execution_count AS ex_cnt
FROM sys.dm_exec_query_stats QS
    CROSS APPLY sys.dm_exec_sql_text(sql_handle) st
    INNER JOIN sys.all_sql_modules SM
        ON SM.object_id = st.objectid
WHERE SM.uses_native_compilation = 1;