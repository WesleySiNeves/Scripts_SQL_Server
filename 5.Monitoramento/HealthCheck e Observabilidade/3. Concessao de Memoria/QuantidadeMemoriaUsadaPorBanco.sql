

/* ==================================================================
--Data: 31/08/2018 
--Autor :Wesley Neves
--Observação: quantidade memoria usada no Buffer Pool

O SQL Server coloca os dados no cache, à medida que são lidos a partir do disco, 
a fim de acelerar futuras consultas. Esse dmv permite ver quantos dados são armazenados em cache 
a qualquer momento e saber como isso muda com o tempo pode ajudar a garantir que seus servidores sejam
 executados  sem problemas e tenham recursos adequados para executar seus sistemas.
 
-- ==================================================================
*/

--SELECT * FROM Monitor.ufnBuscaQuantidadeMemoriaNoBufferPool() AS UBQMNBP

CREATE FUNCTION HealthCheck.ufnBuscaQuantidadeMemoriaNoBufferPool()
 RETURNS TABLE AS RETURN 

 
SELECT
    databases.name AS [DataBaseName],
    COUNT(*) * 8.0 / 1024 AS [MB Usado]
FROM sys.dm_os_buffer_descriptors
INNER JOIN sys.databases
ON databases.database_id = dm_os_buffer_descriptors.database_id
WHERE databases.database_id = DB_ID()
GROUP BY databases.name



GO



--SELECT * FROM Monitor.ufnBuscaQuantidadeTotalPaginasNoBufferPool() AS UBQTPNBP

CREATE OR ALTER FUNCTION Monitor.ufnBuscaQuantidadeTotalPaginasNoBufferPool()
 RETURNS TABLE AS RETURN 

SELECT COUNT(*) AS cached_pages_count , 
        ( COUNT(*) * 8.0 ) / 1024 AS MB , 
        CASE database_id 
          WHEN 32767 THEN 'ResourceDb' 
          ELSE DB_NAME(database_id) 
        END AS Database_name 
    FROM sys.dm_os_buffer_descriptors 
	
    GROUP BY database_id
	ORDER BY  COUNT(*) DESC
	OFFSET 0 ROW FETCH NEXT 10000 ROWS ONLY

    

--SELECT * FROM Monitor.Monitor.ufnBuscaQuantidadeTotalPaginasNoBufferPool() AS UBQTPNBP



	