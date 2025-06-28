
--CREATE DATABASE [cra-sp.implanta.net.br-ESPELHO]  AS COPY OF   [rgprd-sqlsrv-spo01].[cra-sp.implanta.net.br](SERVICE_OBJECTIVE = ELASTIC_POOL( name = "rgprd-elspool-prd01"))
--CREATE DATABASE [cro-sp.implanta.net.br-ESPELHO]  AS COPY OF   [rgprd-sqlsrv-spo01].[cro-sp.implanta.net.br](SERVICE_OBJECTIVE = ELASTIC_POOL( name = "rgprd-elspool-prd01"))
--CREATE DATABASE [oab-ba.implanta.net.br-ESPELHO]  AS COPY OF   [rgprd-sqlsrv-spo01].[oab-ba.implanta.net.br](SERVICE_OBJECTIVE = ELASTIC_POOL( name = "rgprd-elspool-prd01"))
----CREATE SCHEMA Automation
----GO

--EXEC Automation.uspGerarEspelhamentoBancoDados @exercutar =1

CREATE OR ALTER PROCEDURE Automation.uspGerarEspelhamentoBancoDados
(
    @exercutar BIT = 1
)
AS
    BEGIN
        DROP TABLE IF EXISTS #BancosEspelhamento;

        CREATE TABLE #BancosEspelhamento
        (
            SourceServer              VARCHAR(256),
            SourceDatabaseName        VARCHAR(256),
            TargetElastcPoolName      VARCHAR(256),
            TargetDatabaseEspelhoName VARCHAR(256)
        );

        INSERT INTO #BancosEspelhamento(
                                           SourceServer,             --Servidor onde esta o banco de dados a ser gerado a copia 
                                           SourceDatabaseName,       --Nome do banco a ser gerado a copia 
                                           TargetElastcPoolName,     --Elasct pool destino da copia ,
                                           TargetDatabaseEspelhoName --Nome do banco que será o espelho 
                                       )
        VALUES('rgprd-sqlsrv-spo01', 'cra-sp.implanta.net.br', 'rgprd-elspool-prd01', 'cra-sp.implanta.net.br-ESPELHO'),
        ('rgprd-sqlsrv-spo01', 'cro-sp.implanta.net.br', 'rgprd-elspool-prd01', 'cro-sp.implanta.net.br-ESPELHO'),
        ('rgprd-sqlsrv-spo01', 'oab-ba.implanta.net.br', 'rgprd-elspool-prd01', 'oab-ba.implanta.net.br-ESPELHO');

        /* ==================================================================
--Data: 23/03/2021 
--Autor :Wesley Neves

----Exemplo do  Script a ser gerado
--DROP DATABASE [cro-sp.implanta.net.br-ESPELHO]
--CREATE DATABASE [cro-sp.implanta.net.br-ESPELHO]
--AS COPY OF [rgprd-sqlsrv-spo01].[cro-sp.implanta.net.br]
--(SERVICE_OBJECTIVE = ELASTIC_POOL( name = "rgprd-elspool-prd02" ) )
 
-- ==================================================================
*/
        DECLARE @SourceServer              VARCHAR(256),
                @SourceDatabaseName        VARCHAR(256),
                @TargetElastcPoolName      VARCHAR(256),
                @TargetDatabaseEspelhoName VARCHAR(256);

        DECLARE cursor_GeraEspelhamento CURSOR FAST_FORWARD READ_ONLY FOR
        SELECT BE.SourceServer,
               BE.SourceDatabaseName,
               BE.TargetElastcPoolName,
               BE.TargetDatabaseEspelhoName
          FROM #BancosEspelhamento AS BE;

        OPEN cursor_GeraEspelhamento;

        FETCH NEXT FROM cursor_GeraEspelhamento
         INTO @SourceServer,
              @SourceDatabaseName,
              @TargetElastcPoolName,
              @TargetDatabaseEspelhoName;

        WHILE @@FETCH_STATUS = 0
            BEGIN
                DECLARE @Script VARCHAR(MAX) = CONCAT('DROP DATABASE IF EXISTS ', QUOTENAME(@TargetDatabaseEspelhoName), ';');

                SET @Script += CONCAT('CREATE DATABASE ', QUOTENAME(@TargetDatabaseEspelhoName), SPACE(2));
                SET @Script += CONCAT('AS COPY OF', SPACE(1));

                IF(LEN(RTRIM(LTRIM(@SourceServer))) > 0)
                    BEGIN
                        SET @Script += CONCAT(SPACE(2), QUOTENAME(@SourceServer), '.', QUOTENAME(@SourceDatabaseName));
                    END;
                ELSE
                    BEGIN
                        SET @Script += CONCAT(SPACE(2), QUOTENAME(@SourceDatabaseName));
                    END;

                SET @Script += CONCAT('(SERVICE_OBJECTIVE = ELASTIC_POOL( name = "', @TargetElastcPoolName, '"))');

                SELECT (@Script);

                IF(@exercutar = 1)
                    BEGIN
                        EXEC(@Script);
                    END;

                WAITFOR DELAY '00:03:00';

                FETCH NEXT FROM cursor_GeraEspelhamento
                 INTO @SourceServer,
                      @SourceDatabaseName,
                      @TargetElastcPoolName,
                      @TargetDatabaseEspelhoName;
            END;

        CLOSE cursor_GeraEspelhamento;
        DEALLOCATE cursor_GeraEspelhamento;
    END;
