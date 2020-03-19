USE Implanta;

IF (OBJECT_ID('TEMPDB..#Tabelas') IS NOT NULL)
    DROP TABLE #Tabelas;

CREATE TABLE #Tabelas (
    ObjectId INT NOT NULL,
    [Schema] VARCHAR(128) NOT NULL,
    TableName VARCHAR(128) NOT NULL);


INSERT INTO #Tabelas (ObjectId,
                      [Schema],
                      TableName)
SELECT T.object_id,
       S.name AS [Schema],
       T.name AS [TableName]
  FROM sys.tables AS T
  JOIN sys.schemas AS S
    ON T.schema_id = S.schema_id
 WHERE T.type_desc = 'USER_TABLE';


DECLARE @ObjectId  INT,
        @Schema    VARCHAR(128),
        @TableName VARCHAR(128);

DECLARE cursorPercorreTableas CURSOR FAST_FORWARD READ_ONLY FOR
SELECT *
  FROM #Tabelas AS T;

OPEN cursorPercorreTableas;

FETCH NEXT FROM cursorPercorreTableas
 INTO @ObjectId,
      @Schema,
      @TableName;

WHILE @@FETCH_STATUS = 0
BEGIN

    SELECT @ObjectId,
           @Schema,
           @TableName;

    FETCH NEXT FROM cursorPercorreTableas
     INTO @ObjectId,
          @Schema,
          @TableName;
END;

CLOSE cursorPercorreTableas;
DEALLOCATE cursorPercorreTableas;



