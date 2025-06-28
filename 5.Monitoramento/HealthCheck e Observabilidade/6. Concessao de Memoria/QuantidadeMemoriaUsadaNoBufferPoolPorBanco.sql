

/*
Sys.dm_os_buffer_descriptors tem uma linha para cada p�gina de dados que � lida na mem�ria e 
armazenada em cache.
Portanto, o caso de uso � direto. Voc� ser� capaz de saber quais p�ginas est�o no meu buffer. Agora voc� s� precisa se juntar a algumas outras visualiza��es do sistema para obter 
o sentido correto de dados no buffer pool.
*/


/* ==================================================================
--Data: 11/09/2018 
--Autor :Wesley Neves
--Observa��o: Obtenha a utiliza��o do buffer pool por cada banco de dados:
 
-- ==================================================================
*/

SELECT DBName = DB_NAME(dm_os_buffer_descriptors.database_id),
       Size_MB = COUNT(1) / 128
  FROM sys.dm_os_buffer_descriptors
 WHERE dm_os_buffer_descriptors.database_id = DB_ID()
 GROUP BY dm_os_buffer_descriptors.database_id
 


