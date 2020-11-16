UPDATE APD
   SET APD.Periodicidade = 30
  FROM HealthCheck.AcoesPeriodicidadeDias AS APD
 WHERE
    APD.Nome = 'ExpurgarElmah';

SET QUOTED_IDENTIFIER ON;

SET ANSI_NULLS ON;
GO

DROP PROCEDURE IF EXISTS HealthCheck.ExpurgarElmah;
GO

 --EXEC HealthCheck.uspExpurgarElmah @Visualizar = 1, -- bit
 --                                  @Deletar = 0     -- bit
 

CREATE OR ALTER PROCEDURE HealthCheck.uspExpurgarElmah
(
    @Visualizar BIT = 0,
    @Deletar    BIT = 0
)
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

        IF(@Visualizar = 1)
            BEGIN
                SELECT EE.*
                  FROM dbo.ELMAH_Error AS EE
                 WHERE
                    CAST(EE.TimeUtc AS DATE) < CAST(DATEADD(DAY, (@PeriodicidadeExpurgoElmah * -1), GETDATE()) AS DATE);
            END;

        IF(@Deletar = 1)
            BEGIN
                IF(DATEDIFF(DAY, @DataUltimaExecucaoExpurgoElmah, @DiaExecucao) >= @PeriodicidadeExpurgoElmah)
                    BEGIN
                        DELETE EE
                          FROM dbo.ELMAH_Error AS EE
                         WHERE
                            CAST(EE.TimeUtc AS DATE) < CAST(DATEADD(DAY, (@PeriodicidadeExpurgoElmah * -1), GETDATE()) AS DATE);
                    END;
            END;
    END;
GO