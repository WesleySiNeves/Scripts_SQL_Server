

/*
Sys.dm_os_buffer_descriptors tem uma linha para cada página de dados que é lida na memória e 
armazenada em cache.
Portanto, o caso de uso é direto. Você será capaz de saber quais páginas estão no meu buffer. Agora você só precisa se juntar a algumas outras visualizações do sistema para obter 
o sentido correto de dados no buffer pool.
*/


/* ==================================================================
--Data: 11/09/2018 
--Autor :Wesley Neves
--Observação: Obtenha a utilização do buffer pool por cada banco de dados:
 
-- ==================================================================
*/

SELECT DBName = DB_NAME(dm_os_buffer_descriptors.database_id),
       Size_MB = COUNT(1) / 128
  FROM sys.dm_os_buffer_descriptors
 WHERE dm_os_buffer_descriptors.database_id = DB_ID()
 GROUP BY dm_os_buffer_descriptors.database_id
 


