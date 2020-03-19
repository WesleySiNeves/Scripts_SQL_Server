SET QUOTED_IDENTIFIER ON;

SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE Log.uspExpurgoLogsJson
AS
    BEGIN
        SET XACT_ABORT ON;

        IF(OBJECT_ID('TEMPDB..#Configuracoes') IS NOT NULL)
            DROP TABLE #Configuracoes;

        CREATE TABLE #Configuracoes
        (
            Configuracao VARCHAR(100),
            Valor        VARCHAR(100)
        );

        DECLARE @QuantidadeMesesPadraoExpurgarLogs TINYINT = 3;
        DECLARE @QuantidadeMesesPadraoLogsExpurgo TINYINT = 12;

        /*Region Logical Querys*/
        DECLARE @UtilizaArmazenamentoLogsJSON BIT = (
                                                        SELECT TOP 1 ISNULL(TRY_CAST(C.Valor AS BIT), 0)
                                                          FROM Sistema.Configuracoes AS C
                                                         WHERE
                                                            C.Configuracao = 'UtilizaArmazenamentoLogsJSON'
                                                    );
        DECLARE @ExecutouMigracaoLogsJSON BIT = (
                                                    SELECT TOP 1 ISNULL(TRY_CAST(C.Valor AS BIT), 0)
                                                      FROM Sistema.Configuracoes AS C
                                                     WHERE
                                                        C.Configuracao = 'ExecutouMigracaoLogsJSON'
                                                );

        IF(@UtilizaArmazenamentoLogsJSON = 0)
            BEGIN
                THROW 50000, 'Configuração @UtilizaArmazenamentoLogsJSON está com valor incorreto para a execução da procedure', 1;
            END;

        IF(@ExecutouMigracaoLogsJSON = 0)
            BEGIN
                THROW 50000, 'Configuração @ExecutouMigracaoLogsJSON está com valor incorreto para a execução da procedure', 1;
            END;

        DECLARE @DataExecucaoExpurgo DATE = (
                                                SELECT TOP 1 TRY_CAST(C.Valor AS DATE)
                                                  FROM Sistema.Configuracoes AS C
                                                 WHERE
                                                    C.Configuracao = 'DataExecucaoExpurgo'
                                            );
        DECLARE @hoje DATE = GETDATE();
        DECLARE @PrimeiroDiaMes DATE = DATEFROMPARTS(YEAR(@hoje), MONTH(@hoje), 1);

        INSERT INTO #Configuracoes(
                                      Configuracao,
                                      Valor
                                  )
        VALUES(   'Data Configurada para o expurgo', -- COnfiguracao - varchar(100)
                  @DataExecucaoExpurgo
              );

        DECLARE @QtdMesExpurgoLogsAuditoria TINYINT = (
                                                          SELECT TOP 1 ISNULL(TRY_CAST(C.Valor AS TINYINT), @QuantidadeMesesPadraoExpurgarLogs)
                                                            FROM Sistema.Configuracoes AS C
                                                           WHERE
                                                              C.Configuracao = 'QtdMesExpurgoLogsAuditoria'
                                                      );
        DECLARE @QtdMesDeletarRegistrosLogsExpurgo TINYINT = (
                                                                 SELECT TOP 1 ISNULL(TRY_CAST(C.Valor AS TINYINT), @QuantidadeMesesPadraoLogsExpurgo)
                                                                   FROM Sistema.Configuracoes AS C
                                                                  WHERE
                                                                     C.Configuracao = 'QtdMesDeletarRegistrosLogsExpurgo'
                                                             );
        DECLARE @DiaSubtraidoConfiguracaoExpurgarLogs DATE = DATEADD(MONTH, (-@QtdMesExpurgoLogsAuditoria), @PrimeiroDiaMes);
        DECLARE @DiaSubtraidoConfiguracaoDeletarExpurgo DATE = DATEADD(MONTH, (-(@QtdMesDeletarRegistrosLogsExpurgo)), @PrimeiroDiaMes);

        INSERT INTO #Configuracoes(
                                      Configuracao,
                                      Valor
                                  )
        VALUES(   'Data Limite para expurgar os logs', -- COnfiguracao - varchar(100)
                  @DiaSubtraidoConfiguracaoExpurgarLogs
              );

        INSERT INTO #Configuracoes(
                                      Configuracao,
                                      Valor
                                  )
        VALUES(   'Data Limite para excluir os logs da tabela expurgo', -- COnfiguracao - varchar(100)
                  @DiaSubtraidoConfiguracaoDeletarExpurgo
              );

        IF(OBJECT_ID('TEMPDB..#QuantidadeRegistrosParaExclusao') IS NOT NULL)
            DROP TABLE #QuantidadeRegistrosParaExclusao;

        CREATE TABLE #QuantidadeRegistrosParaExclusao
        (
            [Ano]   INT,
            [Mes]   INT,
            [Total] DECIMAL(18, 2)
        );

        IF(OBJECT_ID('TEMPDB..#QuantidadeRegistrosParaInserirExpurgo') IS NOT NULL)
            DROP TABLE #QuantidadeRegistrosParaInserirExpurgo;

        CREATE TABLE #QuantidadeRegistrosParaInserirExpurgo
        (
            [Ano]   INT,
            [Mes]   INT,
            [Total] DECIMAL(18, 2)
        );

        INSERT INTO #QuantidadeRegistrosParaInserirExpurgo(
                                                              Ano,
                                                              Mes,
                                                              Total
                                                          )
        SELECT YEAR(LJ.Data) Ano,
               MONTH(LJ.Data) Mes,
               COUNT(*) Total
          FROM Log.LogsJson AS LJ
         WHERE
           CAST(LJ.Data AS DATE) < @DiaSubtraidoConfiguracaoExpurgarLogs
         GROUP BY
            YEAR(LJ.Data),
            MONTH(LJ.Data);

        INSERT INTO #QuantidadeRegistrosParaExclusao(
                                                        Ano,
                                                        Mes,
                                                        Total
                                                    )
        SELECT YEAR(LJ.Data) Ano,
               MONTH(LJ.Data) Mes,
               COUNT(*) Total
          FROM Expurgo.LogsJson AS LJ
         WHERE
           CAST(LJ.Data AS DATE) < @DiaSubtraidoConfiguracaoDeletarExpurgo
         GROUP BY
            YEAR(LJ.Data),
            MONTH(LJ.Data);

        IF(@hoje >= @DataExecucaoExpurgo)
            BEGIN
                BEGIN TRY
                    IF(EXISTS (SELECT 1 FROM #QuantidadeRegistrosParaExclusao AS QRPE))
                        BEGIN

                            /* declare variables */
                            DECLARE @AnoExpurgo   INT,
                                    @MesExpurgo   INT,
                                    @TotalExpurgo NVARCHAR(4000);

                            DECLARE cursor_ExecutaDeleteExpurgo CURSOR FAST_FORWARD READ_ONLY FOR
                            SELECT IEL.Ano,
                                   IEL.Mes,
                                   IEL.Total
                              FROM #QuantidadeRegistrosParaExclusao AS IEL
                             ORDER BY
                                IEL.Ano,
                                IEL.Mes DESC;

                            OPEN cursor_ExecutaDeleteExpurgo;

                            FETCH NEXT FROM cursor_ExecutaDeleteExpurgo
                             INTO @AnoExpurgo,
                                  @MesExpurgo,
                                  @TotalExpurgo;

                            WHILE @@FETCH_STATUS = 0
                                BEGIN
                                    BEGIN TRAN Task_Expurgo;

                                    DELETE LJ
                                      FROM Expurgo.LogsJson AS LJ WITH(TABLOCK)
                                     WHERE
                                        YEAR(LJ.Data) = @AnoExpurgo
                                        AND MONTH(LJ.Data) = @MesExpurgo;

                                    COMMIT TRAN Task_Expurgo;

                                    FETCH NEXT FROM cursor_ExecutaDeleteExpurgo
                                     INTO @AnoExpurgo,
                                          @MesExpurgo,
                                          @TotalExpurgo;
                                END;

                            CLOSE cursor_ExecutaDeleteExpurgo;
                            DEALLOCATE cursor_ExecutaDeleteExpurgo;
                        END;

                    IF(EXISTS (SELECT 1 FROM #QuantidadeRegistrosParaInserirExpurgo AS QRPE))
                        BEGIN

                            /* declare variables */
                            DECLARE @AnoInsert   INT,
                                    @MesInsert   INT,
                                    @TotalInsert NVARCHAR(4000);

                            DECLARE cursor_ExecutaMigracaoLogsParaExpurgo CURSOR FAST_FORWARD READ_ONLY FOR
                            SELECT IEL.Ano,
                                   IEL.Mes,
                                   IEL.Total
                              FROM #QuantidadeRegistrosParaInserirExpurgo AS IEL
                             ORDER BY
                                IEL.Ano,
                                IEL.Mes DESC;

                            OPEN cursor_ExecutaMigracaoLogsParaExpurgo;

                            FETCH NEXT FROM cursor_ExecutaMigracaoLogsParaExpurgo
                             INTO @AnoInsert,
                                  @MesInsert,
                                  @TotalInsert;

                            WHILE @@FETCH_STATUS = 0
                                BEGIN
                                    BEGIN TRAN Task_InsertExpurgo;

                                    INSERT INTO Expurgo.LogsJson(
                                                                    IdPessoa,
                                                                    IdEntidade,
                                                                    Entidade,
                                                                    IdLogAntigo,
                                                                    Acao,
                                                                    Data,
                                                                    IdSistemaEspelhamento,
                                                                    IPAdress,
                                                                    Conteudo
                                                                )
                                    SELECT LJ.IdPessoa,
                                           LJ.IdEntidade,
                                           LJ.Entidade,
                                           LJ.IdLogAntigo,
                                           LJ.Acao,
                                           LJ.Data,
                                           LJ.IdSistemaEspelhamento,
                                           LJ.IPAdress,
                                           LJ.Conteudo
                                      FROM Log.LogsJson LJ WITH(TABLOCK)
                                     WHERE
                                        YEAR(LJ.Data) = @AnoInsert
                                        AND MONTH(LJ.Data) = @MesInsert;

                                    COMMIT TRAN Task_InsertExpurgo;

                                    BEGIN TRAN Task_DeleteLogs;

                                    DELETE LJ
                                      FROM Log.LogsJson LJ WITH(TABLOCK)
                                     WHERE
                                        YEAR(LJ.Data) = @AnoInsert
                                        AND MONTH(LJ.Data) = @MesInsert;

                                    COMMIT TRAN Task_DeleteLogs;

                                    FETCH NEXT FROM cursor_ExecutaMigracaoLogsParaExpurgo
                                     INTO @AnoExpurgo,
                                          @MesExpurgo,
                                          @TotalExpurgo;
                                END;

                            CLOSE cursor_ExecutaMigracaoLogsParaExpurgo;
                            DEALLOCATE cursor_ExecutaMigracaoLogsParaExpurgo;
                        END;

                    DECLARE @NovoDia DATE = DATEADD(MONTH, 1, GETDATE());

                    UPDATE Sistema.Configuracoes
                       SET Configuracoes.Valor = @NovoDia
                     WHERE
                        Configuracoes.Configuracao = 'DataExecucaoExpurgo';

                    INSERT INTO #Configuracoes(
                                                  Configuracao,
                                                  Valor
                                              )
                    VALUES(   'Proxima Data Configurada Para expurgar', -- Configuracao - varchar(100)
                              @NovoDia                                  -- Valor - varchar(100)
                          );
                END TRY
                BEGIN CATCH
                    IF(@@TRANCOUNT > 0)
                        ROLLBACK;

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
        ELSE
            BEGIN
                SELECT * FROM #Configuracoes AS C;
                SELECT 'DeleteExpurgo' AS Rotina, * FROM #QuantidadeRegistrosParaExclusao AS QRPE
                SELECT 'InsertExpurgo' AS Rotina,* FROM #QuantidadeRegistrosParaInserirExpurgo AS QRPIE;
            END;
    END;
