IF (OBJECT_ID('TEMPDB..#RegistrosDuplicados') IS NOT NULL)
    DROP TABLE #RegistrosDuplicados;


CREATE TABLE #RegistrosDuplicados ([IdLogAntigo] UNIQUEIDENTIFIER PRIMARY KEY);


IF (OBJECT_ID('TEMPDB..#TempOperacoes') IS NOT NULL)
    DROP TABLE #TempOperacoes;


CREATE TABLE #TempOperacoes ([IdLogAntigo] UNIQUEIDENTIFIER PRIMARY KEY);


WITH Dados
  AS (SELECT COUNT(source.IdLogAntigo) Total
      FROM Log.LogsJson AS source
           JOIN
           Expurgo.LogsJson AS target ON target.IdLogAntigo = source.IdLogAntigo
                                         AND target.IdEntidade = source.IdEntidade
     )
INSERT INTO #RegistrosDuplicados
SELECT source.IdLogAntigo
FROM Log.LogsJson AS source
     JOIN
     Expurgo.LogsJson AS target ON target.IdLogAntigo = source.IdLogAntigo;


IF (EXISTS (
           SELECT *
           FROM #RegistrosDuplicados AS RD
           )
   )
BEGIN




    DECLARE @totalInteracoes INT = 150;


    DECLARE @TakeRegistros INT = (
                                 SELECT COUNT(*)
                                 FROM #RegistrosDuplicados AS RD
                                 ) / @totalInteracoes;


    SELECT @totalInteracoes,
           @TakeRegistros;


    --3101426
    --31014
    --== ?3.070.412?

    SET XACT_ABORT ON;

    BEGIN TRY
        /*Region Logical Querys*/

        DECLARE @Inicio INT = 1;
        WHILE (EXISTS (
                      SELECT *
                      FROM #RegistrosDuplicados AS RD
                      )
              )
        BEGIN

            BEGIN TRAN task;

            TRUNCATE TABLE #TempOperacoes;

            INSERT INTO #TempOperacoes
            SELECT TOP (@TakeRegistros)
                *
            FROM #RegistrosDuplicados AS RD;



            DELETE TARGET
            FROM Expurgo.LogsJson TARGET
                 JOIN
                 #TempOperacoes source ON source.IdLogAntigo = TARGET.IdLogAntigo;

            DELETE target
            FROM #RegistrosDuplicados AS target
                 JOIN
                 #TempOperacoes source ON source.IdLogAntigo = target.IdLogAntigo;


            PRINT @Inicio;


            SET @Inicio += 1;

            COMMIT TRAN task;

        END;


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


        PRINT 'Error detected, all changes reversed.';
    END CATCH;
END;