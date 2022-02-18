/* ==================================================================
--Data: 06/02/2019 
--Autor :Wesley Neves
--Observação: Retorna a quantidade de indices
 
-- ==================================================================
*/

DECLARE @Quantidade INT = (
                              SELECT COUNT(*)
                              FROM sys.tables AS T
                                  JOIN sys.indexes AS I
                                      ON T.object_id = I.object_id
                              WHERE I.type > 1
                          );

SELECT @Quantidade;




IF (EXISTS
(
    SELECT *
    FROM sys.procedures AS P
    WHERE P.name = 'uspAutoCreateIndex'
)
   )
BEGIN	

    EXEC HealthCheck.uspAutoCreateIndex @Efetivar = 1,             -- bit
                                        @VisualizarMissing = 0,    -- bit
                                        @VisualizarCreate = 0,     -- bit
                                        @VisualizarAlteracoes = 0; -- bit


END;



IF (EXISTS
(
    SELECT *
    FROM sys.procedures AS P
    WHERE P.name = 'uspAutoCreateIndex'
)
   )
BEGIN	

   
DECLARE @Quantidade INT = (
                              SELECT COUNT(*)
                              FROM sys.tables AS T
                                  JOIN sys.indexes AS I
                                      ON T.object_id = I.object_id
                              WHERE I.type > 1
                          );

SELECT @Quantidade;



END;


