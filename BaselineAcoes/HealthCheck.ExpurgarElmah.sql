CREATE OR ALTER PROCEDURE HealthCheck.ExpurgarElmah
AS
    BEGIN
        DECLARE @DiaExecucao DATE = GETDATE();
        DECLARE @DataUltimaExecucaoExpurgoElmah DATE = (
                                                           SELECT TOP 1 ISNULL(APD.DataUltimaExecucao, APD.DataInicio)
                                                             FROM HealthCheck.AcoesPeriodicidadeDias AS APD
                                                            WHERE
                                                               APD.Nome = 'ExpurgarElmah'
                                                               AND APD.Ativo = 1
                                                       );
        DECLARE @PeriodicidadeExpurgoElmah SMALLINT = (
                                                          SELECT TOP 1 APD.Periodicidade
                                                            FROM HealthCheck.AcoesPeriodicidadeDias AS APD
                                                           WHERE
                                                              APD.Nome = 'ExpurgarElmah'
                                                              AND APD.Ativo = 1
                                                      );

        IF(DATEDIFF(DAY, @DataUltimaExecucaoExpurgoElmah, @DiaExecucao) >= @PeriodicidadeExpurgoElmah)
            BEGIN
                DELETE EE
                  FROM dbo.ELMAH_Error AS EE
                 WHERE
                    CAST(EE.TimeUtc AS DATE) < CAST(DATEADD(DAY, (@PeriodicidadeExpurgoElmah * -1), GETDATE()) AS DATE);
            END;
    END;