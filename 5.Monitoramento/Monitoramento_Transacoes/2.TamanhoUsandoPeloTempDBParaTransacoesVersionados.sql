
/*

O sys.dm_tran_version_store_space_usage é usado para controlar o uso do armazenamento de versão por banco de
 dados em tempdb. Isso é bastante útil no monitoramento proativo do dimensionamento de
  tempdb no requisito de uso de armazenamento de versão de cada banco de dados.
   Este DMV retorna o espaço de armazenamento de versão agregada consumido em tempdb 
   por banco de dados. Não possui argumentos que precisem ser fornecidos. Os resultados mostram o databaseID, 
   a contagem de páginas reservadas
 em tempdb para registros de armazenamento de versão e o espaço total em kilobytes.
*/
SELECT D.database_id,
       D.name,
       DTVSSU.reserved_page_count,
       DTVSSU.reserved_space_kb
FROM sys.dm_tran_version_store_space_usage AS DTVSSU
     JOIN
     sys.databases AS D ON DTVSSU.database_id = D.database_id;