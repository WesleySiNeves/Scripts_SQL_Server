DECLARE @Tabela VARCHAR(100) = 'Log.Logs';


SELECT S.rowcnt
  FROM sys.indexes AS I
  JOIN sys.sysindexes AS S
    ON I.object_id = S.id
 WHERE I.object_id = OBJECT_ID(@Tabela)
   AND I.type_desc = 'CLUSTERED'
   AND S.indid     = 1;


   