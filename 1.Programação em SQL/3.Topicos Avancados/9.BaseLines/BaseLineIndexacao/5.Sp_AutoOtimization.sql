

--EXEC HealthCheck.uspAutoOtimization @Efetivar = 0,                    -- bit
--                                               @Visualizar = 1,                  -- bit
--                                               @QuantidadeDiasIneficiente = 7,      -- tinyint
--                                               @QuantidadeDiasIndicesNaoUsados = 30, -- tinyint
--                                               @QuantidadeDiasLimparDados = 30,      -- tinyint
--                                               @DiaExecucao = '2018-11-14'          -- date


--GO

CREATE OR ALTER PROCEDURE HealthCheck.uspAutoOtimization
(
    @Efetivar BIT = 0,
    @Visualizar BIT = 1,
    @QuantidadeDiasIneficiente TINYINT = 7,
    @QuantidadeDiasIndicesNaoUsados TINYINT = 30,
    @QuantidadeDiasLimparDados TINYINT = 30,
    @DiaExecucao DATE 
)
AS


DECLARE @ConfiguracaoHabilitarAutoTunning BIT = 1;

/*
DECLARE @Efetivar BIT = 1;
DECLARE @Visualizar BIT = 1;
DECLARE @QuantidadeDiasIneficiente TINYINT = 7;
DECLARE @QuantidadeDiasIndicesNaoUsados TINYINT = 30;
DECLARE @QuantidadeDiasLimparDados TINYINT = 30;

*/
-- recuperar da configuracao
DECLARE @DataStartMonitoracao DATE = GETDATE();


DECLARE @Modulo1 TINYINT = 7;

DECLARE @Modulo2 TINYINT = 15;

DECLARE @Modulo3 TINYINT = 30;




DECLARE @mensagem VARCHAR(1000);

SET @DataStartMonitoracao = ISNULL(@DataStartMonitoracao, GETDATE());



IF (@ConfiguracaoHabilitarAutoTunning = 1)
BEGIN

    DECLARE @StartTime DATETIME;

    SET @StartTime = GETDATE();


    /*Executa Snap shot dos indices  (Diario)*/
    EXEC HealthCheck.uspSnapShotIndex @Visualizar = 0;

		PRINT CONCAT(
                    'Indexacao.[Indexacao.sp_SnapShotIndex] Executado:',
                    SPACE(2),
                    'Tempo Decorrido:',
                    DATEDIFF(MILLISECOND, @StartTime, GETDATE()),
                    ' MS'
                );
				
				
				 
		SET @StartTime = GETDATE();


        /*Atualiza Statisticas Necessárias (diario)*/
        EXEC HealthCheck.uspUpdateStats @MostarStatisticas = @Visualizar, -- bit
                                                 @ExecutarAtualizacao = @Efetivar; -- bit

        PRINT CONCAT(
                        'Indexacao.Indexacao.[Indexacao.sp_UpdateStats] Executado:',
                        SPACE(2),
                        'Tempo Decorrido:',
                        DATEDIFF(MILLISECOND, @StartTime, GETDATE()),
                        ' MS',
                        '==>',
                        (DATEDIFF(DAY, @DataStartMonitoracao, @DiaExecucao) % @Modulo1)
                    );


				  

    IF (DATEDIFF(DAY, @DataStartMonitoracao, @DiaExecucao) % @Modulo1 = 0)
    BEGIN

        SET @StartTime = GETDATE();

        /*Resolve indices duplicados (7 dias)*/
        EXEC HealthCheck.uspDeleteDuplicateIndex @Efetivar = @Efetivar,                            -- bit
                                                          @MostrarIndicesDuplicados = @Visualizar,
                                                          @MostrarIndicesMarcadosParaDeletar = @Visualizar, -- bit
                                                          @TableName = NULL;                                -- 'Sistema.ArquivosAnexos';--'Sistema.ArquivosAnexos';

        PRINT CONCAT(
                        'Indexacao.[Indexacao.sp_DeleteDuplicateIndex] Executado:',
                        SPACE(2),
                        'Tempo Decorrido:',
                        DATEDIFF(MILLISECOND, @StartTime, GETDATE()),
                        ' MS',
                        '==>',
                        (DATEDIFF(DAY, @DataStartMonitoracao, @DiaExecucao) % @Modulo1)
                    );


        SET @StartTime = GETDATE();

        /*Executa de analize  eficiencia de indices*/
        EXEC HealthCheck.uspInefficientIndex @percentualAproveitamento = 5,                           --  (Acesso <= 5 %) smallint
                                                      @EfetivarDelecao = @Efetivar,                            -- bit
                                                      @QuantidadeDiasIneficiente = @QuantidadeDiasIneficiente, -- smallint  (7 dias)
                                                      @MostrarIndiceIneficiente = @Visualizar;                 -- bit

        PRINT CONCAT(
                        'Indexacao.[Indexacao.sp_InefficientIndex] Executado:',
                        SPACE(2),
                        'Tempo Decorrido:',
                        DATEDIFF(MILLISECOND, @StartTime, GETDATE()),
                        ' MS',
                        '==>',
                        (DATEDIFF(DAY, @DataStartMonitoracao, @DiaExecucao) % @Modulo1)
                    );

    END;


    /*Cria os indices Faltantes (quinzenal)*/
    IF (DATEDIFF(DAY, @DataStartMonitoracao, @DiaExecucao) % @Modulo2 = 0)
    BEGIN

        SET @StartTime = GETDATE();

        /* Desfragmento dos indices */
        EXEC HealthCheck.uspindexDesfrag @MostrarIndices = @Visualizar, -- bit
                                                  @MinFrag = 10,                 -- smallint
                                                  @MinPageCount = 1000,          -- smallint
                                                  @Efetivar = @Efetivar;         -- bit



        PRINT CONCAT(
                        'Indexacao.[Indexacao.sp_DesfragIndex] Executado:',
                        SPACE(2),
                        'Tempo Decorrido:',
                        DATEDIFF(MILLISECOND, @StartTime, GETDATE()),
                        ' MS',
                        '==>',
                        (DATEDIFF(DAY, @DataStartMonitoracao, @DiaExecucao) % @Modulo2)
                    );


        SET @StartTime = GETDATE();
        /*Cria os Statisticas Colunares de tabelas que foram acessados pelos indices*/
        EXEC HealthCheck.uspAutoManegerStats @MostrarStatistica = @Visualizar, -- bit
                                                      @Efetivar = @Efetivar;            -- bit



        PRINT CONCAT(
                        'Indexacao.[Indexacao.sp_AutoManegerStats] Executado:',
                        SPACE(2),
                        'Tempo Decorrido:',
                        DATEDIFF(MILLISECOND, @StartTime, GETDATE()),
                        ' MS',
                        '==>',
                        (DATEDIFF(DAY, @DataStartMonitoracao, @DiaExecucao) % @Modulo1)
                    );




    END;

    IF (DATEDIFF(DAY, @DataStartMonitoracao, @DiaExecucao) % @Modulo3 = 0)
    BEGIN


        SET @StartTime = GETDATE();
        /*Deletar os indices que não estão sendo usados pelo otimizador por mais de X dias*/
        EXEC HealthCheck.uspUnusedIndex @EfetivarDelecao = @Efetivar,       -- bit
                                                 @QuantidadeDiasConfigurado = @QuantidadeDiasIndicesNaoUsados,    -- smallint (30 dias)
                                                 @MostrarIndice = @Visualizar; -- bit


        PRINT CONCAT(
                        'Indexacao.[Indexacao.Indexacao.sp_UnusedIndex] Executado:',
                        SPACE(2),
                        'Tempo Decorrido:',
                        DATEDIFF(MILLISECOND, @StartTime, GETDATE()),
                        ' MS',
                        '==>',
                        (DATEDIFF(DAY, @DataStartMonitoracao, @DiaExecucao) % @Modulo3)
                    );

    END;



    SET @StartTime = GETDATE();

    /*Cria Automaticamente Missing Index*/
    EXEC HealthCheck.uspAutoCreateIndex @Efetivar = @Efetivar,           -- bit
                                                 @Visualizar = @Visualizar; -- bit


    PRINT CONCAT(
                    'Indexacao.[Indexacao.sp_AutoCreateIndex] Executado:',
                    SPACE(2),
                    'Tempo Decorrido:',
                    DATEDIFF(MILLISECOND, @StartTime, GETDATE()),
                    ' MS',
                    '==>',
                    (DATEDIFF(DAY, @DataStartMonitoracao, @DiaExecucao) % @Modulo2)
                );




    EXEC HealthCheck.uspSnapShotClear @diasExpurgo = @QuantidadeDiasLimparDados; -- smallint


END;

