
/* ==================================================================
--Data: 09/02/2021 
--Autor :Wesley Neves
--Observação: Seleciona todas as View , procedures e Function para excluir
as que deram erros não serão excluidas pois estão vinculadas as tabelas
 
-- ==================================================================
*/

IF(OBJECT_ID('TEMPDB..#Dados') IS NOT NULL)
    DROP TABLE #Dados;

CREATE TABLE #Dados
(
    [SchemaName] VARCHAR(128),
    [ObjetoName] VARCHAR(128),
    [Tipo]       VARCHAR(9),
    [Script]     VARCHAR(272)
);

WITH ObjetosImplanta
    AS
    (
        SELECT S.name AS SchemaName,
               V.name AS ObjetoName,
               Tipo = 'View'
          FROM sys.views AS V
               JOIN sys.schemas AS S ON S.schema_id = V.schema_id
         WHERE
            V.name <> 'database_firewall_rules'
        UNION
        SELECT S.name AS SchemaName,
               P.name AS ObjetoName,
               'Procedure' AS Tipo
          FROM sys.procedures AS P
               JOIN sys.schemas AS S ON S.schema_id = P.schema_id
        UNION
        SELECT ROUTINE_SCHEMA AS SchemaName,
               ROUTINE_NAME AS ObjetoName,
               'FUNCTION' AS Tipo
          FROM INFORMATION_SCHEMA.ROUTINES
         WHERE
            ROUTINE_TYPE = 'function'
    )
INSERT INTO #Dados(
                      SchemaName,
                      ObjetoName,
                      Tipo,
                      Script
                  )
SELECT R.SchemaName,
       R.ObjetoName,
       R.Tipo,
       Script = CONCAT('DROP ', R.Tipo, ' ', R.SchemaName, '.', R.ObjetoName)
  FROM ObjetosImplanta R;

/* declare variables */
DECLARE @SchemaName VARCHAR(128),
        @ObjetoName VARCHAR(128),
        @Tipo       VARCHAR(9),
        @Script     VARCHAR(400);

DECLARE cursor_DeletaObjetos CURSOR FAST_FORWARD READ_ONLY FOR
SELECT DISTINCT D.SchemaName, D.ObjetoName, D.Tipo, D.Script FROM #Dados AS D;

OPEN cursor_DeletaObjetos;

FETCH NEXT FROM cursor_DeletaObjetos
 INTO @SchemaName,
      @ObjetoName,
      @Tipo,
      @Script;

WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            EXEC(@Script);
        END TRY
        BEGIN CATCH
            DECLARE @ErrorNumber INT = ERROR_NUMBER();
            DECLARE @ErrorLine INT = ERROR_LINE();
            DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
            DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
            DECLARE @ErrorState INT = ERROR_STATE();

            PRINT 'Actual error number: ' + CAST(@ErrorNumber AS VARCHAR(MAX));
            PRINT 'Actual line number: ' + CAST(@ErrorLine AS VARCHAR(MAX));
            PRINT '@ErrorMessage: ' + CAST(@ErrorMessage AS VARCHAR(MAX));
            PRINT '@ErrorSeverity: ' + CAST(@ErrorLine AS VARCHAR(MAX));
            PRINT '@ErrorState: ' + CAST(@ErrorLine AS VARCHAR(MAX));

            RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        END CATCH;

        FETCH NEXT FROM cursor_DeletaObjetos
         INTO @SchemaName,
              @ObjetoName,
              @Tipo,
              @Script;
    END;

CLOSE cursor_DeletaObjetos;
DEALLOCATE cursor_DeletaObjetos;