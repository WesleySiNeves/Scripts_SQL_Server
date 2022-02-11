ALTER PROCEDURE Automation.uspDeletarEspelhamentoBancoDados

AS
    BEGIN
	   
		DROP DATABASE IF EXISTS [oab-ba.implanta.net.br-ESPELHO] ;
		DROP DATABASE IF EXISTS [cra-sp.implanta.net.br-ESPELHO] ;
		DROP DATABASE IF EXISTS [cro-sp.implanta.net.br-ESPELHO] ;
		DROP DATABASE IF EXISTS [crmv-sp.implanta.net.br-ESPELHO] ;
		 
		
    END;

GO
