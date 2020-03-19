SELECT 
    SSIH.SnapShotDate,
    COUNT(SSIH.ObjectId) AS Objetos
FROM HealthCheck.SnapShotIndexHistory AS SSIH
GROUP BY SSIH.SnapShotDate
ORDER BY SSIH.SnapShotDate

DECLARE @schema VARCHAR(MAX);

EXEC HealthCheck.sp_WhoIsActive 
                                @show_own_spid = 0,        -- bit
                                @show_system_spids = 0,    -- bit
                                @show_sleeping_spids = 1,     -- tinyint
                                @get_full_inner_text = 1,  -- bit
                                @get_plans = 1,               -- tinyint
                                @get_outer_command = 1,    -- bit
                                @get_transaction_info = 1, -- bit
                                @get_task_info = 1,           -- tinyint
                                @get_locks = 1,            -- bit
                                @get_avg_time = 1,         -- bit
                                @get_additional_info = 1;  -- bit
                               

SELECT * FROM  sys.tables AS T
JOIN sys.indexes AS I ON T.object_id = I.object_id

WHERE I.type >1




SELECT   S.name, T.name,COUNT(I.index_id) TotalIndicesNonClustered FROM  sys.tables AS T
JOIN sys.schemas AS S ON T.schema_id = S.schema_id
JOIN sys.indexes AS I ON T.object_id = I.object_id
WHERE I.type >1
GROUP BY S.name, T.name
ORDER BY TotalIndicesNonClustered DESC



EXEC HealthCheck.uspAutoCreateIndex @Efetivar = 0, -- bit
                                    @VisualizarMissing = 1, -- bit
                                    @VisualizarCreate = 1, -- bit
                                    @VisualizarAlteracoes = 1, -- bit
                                    @defaultTunningPerform =100;
                                    




EXEC HealthCheck.uspAutoManegerStats @MostrarStatistica = 1, -- bit
                                     @Efetivar = 0 -- bit





                                     
EXEC HealthCheck.uspDeleteDuplicateIndex @Efetivar =0, -- bit
                                         @MostrarIndicesDuplicados = 1, -- bit
                                         @MostrarIndicesMarcadosParaDeletar = 1; -- bit
                                       

EXEC HealthCheck.uspIndexDesfrag @MostrarIndices = 1, -- bit
                                 @Efetivar = 0 -- bit


EXEC HealthCheck.uspInefficientIndex @EfetivarDelecao = 0, -- bit
                                     @MostrarIndiceIneficiente = 1; -- bit




EXEC HealthCheck.uspAllIndex  @ObjectName = 'Financeiro.Debitos';              -- varchar(128)
                           


EXEC HealthCheck.uspSnapShotIndex @Visualizar = 1, -- bit
                                  @Efetivar = 0 ;-- bit

EXEC HealthCheck.uspUnusedIndex @EfetivarDelecao = 0, -- bit
                                @MostrarIndice = 1; -- bit



EXEC HealthCheck.uspUpdateStats @MostarStatisticas = 1, -- bit
                                @ExecutarAtualizacao = 1; -- bit
                                


EXEC HealthCheck.uspDeleteOverlappingStats @MostarStatisticas = 1, -- bit
	                                           @Executar = 1           -- bit
	





EXEC HealthCheck.uspIndexMedia 