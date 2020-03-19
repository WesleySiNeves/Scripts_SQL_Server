CREATE OR ALTER PROCEDURE HealthCheck.uspSnapShotClear (@diasExpurgo SMALLINT = 30)
AS
BEGIN

    DECLARE @maxAnalise INT = 0;

    ;WITH Dados
    AS (SELECT DENSE_RANK() OVER (PARTITION BY SSIH.ObjectId, SSIH.IndexId ORDER BY SSIH.SnapShotDate) AS Analise
        FROM HealthCheck.SnapShotIndexHistory AS SSIH
       )
    SELECT @maxAnalise = ISNULL(MAX(Dados.Analise), 0)
    FROM Dados;

    IF (@maxAnalise >= @diasExpurgo)
    BEGIN

        DELETE HIST
        FROM HealthCheck.SnapShotIndexHistory HIST;

        DELETE IX
        FROM HealthCheck.SnapShotIndex IX;
    END;

END;

GO


