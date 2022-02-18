CREATE TABLE Log.TableNames
(
    IdTableName SMALLINT PRIMARY KEY IDENTITY(1, 1),
    [ShemaName] VARCHAR(128),
    [TableName] VARCHAR(128),
	Entidade AS (CONCAT([ShemaName],'.',[TableName]))
)



--WITH Dados
--    AS
--    (
--        SELECT LJ.Entidade,
--               COUNT(*) QuatidadeRegistros,
--               MIN(LEN(LJ.Entidade)) Tamanho
--          FROM Log.LogsJson AS LJ
--         GROUP BY
--            LJ.Entidade
--    )
--SELECT * FROM Dados R ORDER BY R.Tamanho DESC;



WITH Dados
    AS
    (
        SELECT IdTableName = ROW_NUMBER() OVER (ORDER BY(SELECT NULL)),
               ShemaName = S.name,
               TableName = T.name
          FROM sys.tables AS T
               JOIN sys.schemas AS S ON T.schema_id = S.schema_id
         WHERE
            S.name NOT IN ('HangFire', '$(HangFireSchema)')
    )
SELECT R.IdTableName, R.ShemaName, R.TableName,
X = CONCAT('retorno.Add(new TableNamesEntity {  IdTableName =',R.IdTableName,', ShemaName = ','"', R.ShemaName,'"',', TableName = ','"', R.TableName,'"',' });')

 FROM Dados R
