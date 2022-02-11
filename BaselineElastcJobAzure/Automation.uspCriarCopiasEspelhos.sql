ALTER PROCEDURE Automation.uspCriarCopiasEspelhos

AS
BEGIN
    

    CREATE DATABASE [oab-ba.implanta.net.br-ESPELHO]   AS COPY OF   [oab-ba.implanta.net.br](SERVICE_OBJECTIVE = ELASTIC_POOL( name = "rgprd-elspool-prd01")) 
	CREATE DATABASE [cra-sp.implanta.net.br-ESPELHO]   AS COPY OF   [cra-sp.implanta.net.br](SERVICE_OBJECTIVE = ELASTIC_POOL( name = "rgprd-elspool-prd01")) 
    CREATE DATABASE [cro-sp.implanta.net.br-ESPELHO]   AS COPY OF   [cro-sp.implanta.net.br](SERVICE_OBJECTIVE = ELASTIC_POOL( name = "rgprd-elspool-prd01")) 
	CREATE DATABASE [crmv-sp.implanta.net.br-ESPELHO]  AS COPY OF   [crmv-sp.implanta.net.br](SERVICE_OBJECTIVE = ELASTIC_POOL( name = "rgprd-elspool-prd01")) 
END;
GO
