
/*

O sys.dm_tran_version_store_space_usage � usado para controlar o uso do armazenamento de vers�o por banco de
 dados em tempdb. Isso � bastante �til no monitoramento proativo do dimensionamento de
  tempdb no requisito de uso de armazenamento de vers�o de cada banco de dados.
   Este DMV retorna o espa�o de armazenamento de vers�o agregada consumido em tempdb 
   por banco de dados. N�o possui argumentos que precisem ser fornecidos. Os resultados mostram o databaseID, 
   a contagem de p�ginas reservadas
 em tempdb para registros de armazenamento de vers�o e o espa�o total em kilobytes.
*/
SELECT D.database_id,
       D.name,
       DTVSSU.reserved_page_count,
       DTVSSU.reserved_space_kb
FROM sys.dm_tran_version_store_space_usage AS DTVSSU
     JOIN
     sys.databases AS D ON DTVSSU.database_id = D.database_id;