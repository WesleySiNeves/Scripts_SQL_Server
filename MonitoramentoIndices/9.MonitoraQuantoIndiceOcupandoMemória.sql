


SET  TRANSACTION ISOLATION LEVEL READ UNCOMMITTED ;

-- Consumo de memoria por índices e deve ser rodada por database.

WITH Dados AS (
SELECT  
		COUNT(*) AS cached_pages_count ,
        obj.name AS BaseTableName ,
		obj.object_id,
        obj.IndexName ,
        obj.IndexTypeDesc
		
FROM    sys.dm_os_buffer_descriptors AS bd
        INNER JOIN ( SELECT s_obj.name ,
                            s_obj.index_id ,
                            s_obj.allocation_unit_id ,
                            s_obj.object_id ,
                            i.name IndexName ,
                            i.type_desc IndexTypeDesc
						
                     FROM   ( SELECT    OBJECT_NAME(p.object_id) AS name ,
                                        p.index_id ,
                                        au.allocation_unit_id ,
                                        p.object_id
                              FROM      sys.allocation_units AS au
                                        INNER JOIN sys.partitions AS p ON au.container_id = p.hobt_id
                                                              AND ( au.type = 1
                                                              OR au.type = 3
                                                              )
                              UNION ALL
                              SELECT    OBJECT_NAME(p.object_id) AS name ,
                                        p.index_id ,
                                        au.allocation_unit_id ,
                                        p.object_id
                              FROM      sys.allocation_units AS au
                                        INNER JOIN sys.partitions AS p ON au.container_id = p.partition_id
                                                              AND au.type = 2
                            ) AS s_obj
                            LEFT JOIN sys.indexes i ON i.index_id = s_obj.index_id
                                                       AND i.object_id = s_obj.object_id
					
                   ) AS obj ON bd.allocation_unit_id = obj.allocation_unit_id
WHERE   bd.database_id = DB_ID()
AND  obj.name NOT  LIKE 'plan_p%'
AND  obj.name NOT  LIKE 'sys%' 
GROUP BY obj.name ,
		obj.object_id,
        obj.index_id ,
        obj.IndexName ,
        obj.IndexTypeDesc
	
),
Resumo AS (
SELECT R.cached_pages_count,
	   R.object_id,
	  [Total MB] = CAST(((R.cached_pages_count * 8) /1024) AS DECIMAL(18,4)),
       R.BaseTableName,
       R.IndexName,
       R.IndexTypeDesc
	 --  [Total de memoria GB reservada as paginas de indice acessado] =  (CAST((SUM(R.MB) OVER() / 1024) AS DECIMAL(18,4))) 
	 FROM Dados R
)
SELECT R.cached_pages_count,
       R.[Total MB],
       R.BaseTableName,
	   R.object_id,
       R.IndexName,
       R.IndexTypeDesc,
	   [Memoria Alocada MB] =  SUM(r.[Total MB]) OVER() FROM  Resumo R
	   WHERE R.[Total MB] > 0
ORDER BY R.cached_pages_count DESC;



-- ==================================================================
--Observação: para teste limpe a memoria no ambiente de teste e  rode um selec
/*
 */
-- ==================================================================

--CHECKPOINT;
---- Limpa buffers (comandos add-hoc)
-- DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS ; -- deleta o cache da query 
-- GO
--  DBCC  FREEPROCCACHE WITH NO_INFOMSGS; --deleta o plano execução ja feito
--  GO
--  DBCC FREESESSIONCACHE WITH NO_INFOMSGS