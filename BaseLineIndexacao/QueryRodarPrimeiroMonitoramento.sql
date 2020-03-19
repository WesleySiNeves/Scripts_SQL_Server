

/* ==================================================================
--Data: 29/11/2018 
--Autor :Wesley Neves
--Observação: query para o power bi usar  a uspMissingIndex
  
-- ==================================================================
*/

EXEC HealthCheck.uspMissingIndex






/* ==================================================================
--Data: 29/11/2018 
--Autor :Wesley Neves
--Observação: query para o power bi usar  a uspAutoCreateIndex
  
-- ==================================================================
*/

EXEC HealthCheck.uspAutoCreateIndex @Efetivar = 0, -- bit
                                    @VisualizarMissing = 0, -- bit
                                    @VisualizarCreate = 1; -- bit
                                    

                                    


/* ==================================================================
--Data: 29/11/2018 
--Autor :Wesley Neves
--Observação: query para o power bi usar  a uspAutoManegerStats
  
-- ==================================================================
*/

EXEC HealthCheck.uspAutoManegerStats @MostrarStatistica = 1, -- bit
                                     @Efetivar = 0; -- bit





/* ==================================================================
--Data: 29/11/2018 
--Autor :Wesley Neves
--Observação: query para o power bi usar  a uspDeleteDuplicateIndex
  
-- ==================================================================
*/

EXEC HealthCheck.uspDeleteDuplicateIndex @Efetivar = 0, -- bit
                                         @MostrarIndicesDuplicados = 1, -- bit
                                         @MostrarIndicesMarcadosParaDeletar  = 0;





/* ==================================================================
--Data: 29/11/2018 
--Autor :Wesley Neves
--Observação: query para o power bi usar  a uspIndexDesfrag
  
-- ==================================================================
*/

EXEC HealthCheck.uspIndexDesfrag @MostrarIndices = 1, -- bit
                                 @Efetivar = 0;-- bit




/* ==================================================================
--Data: 29/11/2018 
--Autor :Wesley Neves
--Observação: query para o power bi usar  a uspInefficientIndex
  
-- ==================================================================
*/
DECLARE @Analise INT =(SELECT MAX(SSIH.Analise) FROM HealthCheck.SnapShotIndexHistory AS SSIH)

EXEC HealthCheck.uspInefficientIndex @EfetivarDelecao = 0, -- bit
									 @NumberOfDaysForInefficientIndex = @Analise,
                                     @MostrarIndiceIneficiente = 1;-- bit
									 






/* ==================================================================
--Data: 29/11/2018 
--Autor :Wesley Neves
--Observação: query para o power bi usar  a uspUnusedIndex
  
-- ==================================================================
*/

DECLARE @AnaliseNowUsage INT =(SELECT MAX(SSIH.Analise) FROM HealthCheck.SnapShotIndexHistory AS SSIH)

EXEC HealthCheck.uspUnusedIndex @EfetivarDelecao = 0, -- bit
                                @QuantidadeDiasConfigurado = @AnaliseNowUsage, -- smallint
                                @MostrarIndice = 1 -- bit








                                     
