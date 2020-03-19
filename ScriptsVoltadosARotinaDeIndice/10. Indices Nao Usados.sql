

WITH Dados
  AS (SELECT S.database_id,
			S.object_id,
             TableName = CONCAT(SCHEMA_NAME(T.schema_id),'.',OBJECT_NAME(S.object_id)),
             --I.type_desc,
             Indice = I.name,
             S.user_seeks + S.user_scans + S.user_lookups AS [Leitura],
             IIF(S.user_seeks + S.user_scans + S.user_lookups = 0, 'N', 'S') AS UsadoNoBanco,
             IIF(S.user_updates > 0, 'S', 'N') AS EscritoNoBanco,
             S.user_seeks,
             S.user_scans,
             S.user_lookups,
             S.user_updates,
             --S.last_user_seek,
             --S.last_user_scan,
             --S.last_user_lookup,
             --S.last_user_update,
			 Obj.create_date,
			-- Obj.modify_date,
             DiasSEMUso = DATEDIFF(DAY, COALESCE(S.last_user_seek, S.last_user_scan,S.last_user_lookup), GETDATE()),
			 DiasNaBase =  DATEDIFF(DAY, Obj.create_date,GETDATE())
      FROM sys.dm_db_index_usage_stats S
           JOIN
           sys.indexes AS I
           JOIN
           sys.tables AS T ON I.object_id = T.object_id ON S.object_id = I.object_id
                                                           AND S.index_id = I.index_id
			JOIN 
			(
			SELECT O.object_id, O.create_date,O.modify_date FROM  sys.objects AS O
	
			) AS Obj ON I.object_id = Obj.object_id
      WHERE SCHEMA_NAME(T.schema_id) NOT IN ( 'HangFire' )
            AND I.type_desc NOT IN ( 'CLUSTERED' )
     )
SELECT *
FROM Dados R
--WHERE R.Indice =''
ORDER BY
    R.Leitura DESC;


	
SELECT * FROM sys.dm_db_index_usage_stats AS DDIUS


;WITH Dados
   AS (SELECT TableName = CONCAT(S.name, '.', T.name),
              I.object_id,
              IndexName = I.name,
              I.index_id,
              I.type,
              I.fill_factor,
              I.has_filter
       FROM sys.indexes AS I
            JOIN
            sys.tables AS T ON I.object_id = T.object_id
            JOIN
            sys.schemas AS S ON T.schema_id = S.schema_id
       WHERE I.type_desc NOT IN ('CLUSTERED')
	   AND S.name NOT  IN  ('HangFire')

      )
SELECT R.TableName,
       [TotalIndexPorTable] = COUNT(R.IndexName) OVER (PARTITION BY R.object_id),
       R.object_id,
       R.IndexName,
       R.index_id,
       R.type,
       R.fill_factor,
       R.has_filter
FROM Dados R

--AND I.object_id ='2919182'

SELECT IC.index_id,
       IC.index_column_id,
       C.name,
	   type =T.name
FROM sys.index_columns AS IC
     JOIN
     sys.columns AS C ON IC.object_id =
	  C.object_id AND IC.column_id = C.column_id
	 JOIN sys.types AS T ON C.system_type_id = T.system_type_id
WHERE IC.object_id = '2919182'
AND IC.index_column_id =1
AND IC.index_id = 25

