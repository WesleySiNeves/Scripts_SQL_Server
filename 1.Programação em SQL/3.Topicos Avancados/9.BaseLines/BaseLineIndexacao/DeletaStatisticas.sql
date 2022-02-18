

/*Resolve deploy */

DECLARE @deletar BIT = 0;

IF(OBJECT_ID('TEMPDB..#DadosADeletar') IS NOT NULL)
    DROP TABLE #DadosADeletar;

CREATE TABLE #DadosADeletar
(
    [SchemaName] NVARCHAR(128),
    [TableName]  NVARCHAR(128),
    [Delet]      NVARCHAR(128),
    [Script]     NVARCHAR(402)
);

WITH Dados
    AS
    (
        SELECT S2.name AS SchemaName,
               T.name AS TableName,
               S.name AS Delet
          FROM sys.stats AS S
               JOIN sys.tables AS T ON S.object_id = T.object_id
               JOIN sys.schemas AS S2 ON T.schema_id = S2.schema_id
         WHERE
            S.name LIKE '%Stats%'
    )
INSERT INTO #DadosADeletar(
                              SchemaName,
                              TableName,
                              Delet,
                              Script
                          )
SELECT R.SchemaName,
       R.TableName,
       R.Delet,
       Script = CONCAT('DROP STATISTICS ', R.SchemaName, '.', R.TableName, '.', R.Delet)
  FROM Dados R;

/* declare variables */
DECLARE @Comando NVARCHAR(800);

DECLARE cursor_DeletaStatis CURSOR FAST_FORWARD READ_ONLY FOR
SELECT DAD.Script FROM #DadosADeletar AS DAD;

OPEN cursor_DeletaStatis;

FETCH NEXT FROM cursor_DeletaStatis
 INTO @Comando;

WHILE @@FETCH_STATUS = 0
    BEGIN

	IF(@deletar =1)
	BEGIN
        EXEC sys.sp_executesql @Comando;
			
	END
	ELSE
	BEGIN
	    PRINT(@Comando)
	END
    
        FETCH NEXT FROM cursor_DeletaStatis
         INTO @Comando;
    END;

CLOSE cursor_DeletaStatis;
DEALLOCATE cursor_DeletaStatis;
