/*
Post-Deployment Script Template							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.		
 Use SQLCMD syntax to include a file in the post-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the post-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/
/*  =========================================================== 
    *  Work item: BUG 14428 
    *  Author: Penhiel
    *  Obs: Seperarando os usuarios, para identificar melhor os problemas de performance
    *   ===========================================================  
    */

	--implanta
	IF NOT EXISTS (SELECT [name]
                FROM [sys].[database_principals]
                WHERE [type] = N'S' AND [name] = N'implanta.net')
	Begin
		CREATE USER [implanta.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    
	END
	ALTER ROLE db_owner ADD MEMBER [implanta.net]
    ALTER USER [implanta.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';

	--logon
	IF NOT EXISTS (SELECT [name]
                FROM [sys].[database_principals]
                WHERE [type] = N'S' AND [name] = N'logon.net')
	Begin
		CREATE USER [logon.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    
	END
	ALTER ROLE db_owner ADD MEMBER [logon.net]
    ALTER USER [logon.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';

	--siscont
	IF NOT EXISTS (SELECT [name]
                FROM [sys].[database_principals]
                WHERE [type] = N'S' AND [name] = N'siscont.net')
	Begin
		CREATE USER [siscont.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    
	END
	ALTER ROLE db_owner ADD MEMBER [siscont.net]
    ALTER USER [siscont.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';

	--pcs
	IF NOT EXISTS (SELECT [name]
                FROM [sys].[database_principals]
                WHERE [type] = N'S' AND [name] = N'pcs.net')
	Begin
		CREATE USER [pcs.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    
	END
	ALTER ROLE db_owner ADD MEMBER [pcs.net]
    ALTER USER [pcs.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';

	--agendafinanceira
	IF NOT EXISTS (SELECT [name]
                FROM [sys].[database_principals]
                WHERE [type] = N'S' AND [name] = N'agendafinanceira.net')
	Begin
		CREATE USER [agendafinanceira.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    
	END
	
    ALTER ROLE db_owner ADD MEMBER [agendafinanceira.net]
    ALTER USER [agendafinanceira.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';


	--auditoria
	IF NOT EXISTS (SELECT [name]
                FROM [sys].[database_principals]
                WHERE [type] = N'S' AND [name] = N'auditoria.net')
	Begin
		CREATE USER [auditoria.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    
	END
	ALTER ROLE db_owner ADD MEMBER [auditoria.net]
    ALTER USER [auditoria.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';

	--comprascontratos
	IF NOT EXISTS (SELECT [name]
                FROM [sys].[database_principals]
                WHERE [type] = N'S' AND [name] = N'comprascontratos.net')
	Begin
		CREATE USER [comprascontratos.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    
	END
	ALTER ROLE db_owner ADD MEMBER [comprascontratos.net]
    ALTER USER [comprascontratos.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';


	--cursos
	IF NOT EXISTS (SELECT [name]
                FROM [sys].[database_principals]
                WHERE [type] = N'S' AND [name] = N'cursos.net')
	Begin
		CREATE USER [cursos.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    
	END

    ALTER USER [cursos.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
	ALTER ROLE db_owner ADD MEMBER [cursos.net]


	--gestaoTCU
	IF NOT EXISTS (SELECT [name]
                FROM [sys].[database_principals]
                WHERE [type] = N'S' AND [name] = N'gestaoTCU.net')
	Begin
		CREATE USER [gestaoTCU.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    
	END
    
    ALTER USER [gestaoTCU.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
	ALTER ROLE db_owner ADD MEMBER [gestaoTCU.net]


	--licitacao
	IF NOT EXISTS (SELECT [name]
                FROM [sys].[database_principals]
                WHERE [type] = N'S' AND [name] = N'licitacao.net')
	Begin
		CREATE USER [licitacao.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    
	END

    ALTER USER [licitacao.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
	ALTER ROLE db_owner ADD MEMBER [licitacao.net]


	--portalTransparencia
	IF NOT EXISTS (SELECT [name]
                FROM [sys].[database_principals]
                WHERE [type] = N'S' AND [name] = N'portalTransparencia.net')
	Begin
		CREATE USER [portalTransparencia.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    
	END

    ALTER USER [portalTransparencia.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
	ALTER ROLE db_owner ADD MEMBER [portalTransparencia.net]


	--servicosOnline
	IF NOT EXISTS (SELECT [name]
                FROM [sys].[database_principals]
                WHERE [type] = N'S' AND [name] = N'servicosOnline.net')
	Begin
		CREATE USER [servicosOnline.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    
	END

    ALTER USER [servicosOnline.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
	ALTER ROLE db_owner ADD MEMBER [servicosOnline.net]


	--sialm
	IF NOT EXISTS (SELECT [name]
                FROM [sys].[database_principals]
                WHERE [type] = N'S' AND [name] = N'sialm.net')
	Begin
		CREATE USER [sialm.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    
	END

    ALTER USER [sialm.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
	ALTER ROLE db_owner ADD MEMBER [sialm.net]

	--sicaf
	IF NOT EXISTS (SELECT [name]
                FROM [sys].[database_principals]
                WHERE [type] = N'S' AND [name] = N'siscaf.net')
	Begin
		CREATE USER [siscaf.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    
	END

	ALTER USER [siscaf.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    ALTER ROLE db_owner ADD MEMBER [siscaf.net]

	--sisdoc
	IF NOT EXISTS (SELECT [name]
					FROM [sys].[database_principals]
					WHERE [type] = N'S' AND [name] = N'sisdoc.net')
	Begin
		CREATE USER [sisdoc.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    
	END
	ALTER USER [sisdoc.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    ALTER ROLE db_owner ADD MEMBER [sisdoc.net]

	--sispad
	IF NOT EXISTS (SELECT [name]
					FROM [sys].[database_principals]
					WHERE [type] = N'S' AND [name] = N'sispad.net')
	Begin
		CREATE USER [sispad.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    
	END
	ALTER USER [sispad.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    ALTER ROLE db_owner ADD MEMBER [sispad.net]


	--sispat
	IF NOT EXISTS (SELECT [name]
					FROM [sys].[database_principals]
					WHERE [type] = N'S' AND [name] = N'sispat.net')
	Begin
		CREATE USER [sispat.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    
	END
    ALTER USER [sispat.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
	ALTER ROLE db_owner ADD MEMBER [sispat.net]


    --programasprojetos
	IF NOT EXISTS (SELECT [name]
					FROM [sys].[database_principals]
					WHERE [type] = N'S' AND [name] = N'programasprojetos.net')
	Begin
		CREATE USER [programasprojetos.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    
	END

    ALTER USER [programasprojetos.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
	ALTER ROLE db_owner ADD MEMBER [programasprojetos.net]

	--visaonacional
	IF NOT EXISTS (SELECT [name]
					FROM [sys].[database_principals]
					WHERE [type] = N'S' AND [name] = N'visaonacional.net')
	Begin
		CREATE USER [visaonacional.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    
	END

    ALTER USER [visaonacional.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
	ALTER ROLE db_owner ADD MEMBER [visaonacional.net]



	--App 
	IF NOT EXISTS (SELECT [name]
					FROM [sys].[database_principals]
					WHERE [type] = N'S' AND [name] = N'app.net')
	Begin
		CREATE USER [app.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    
	END

    ALTER USER [app.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
	ALTER ROLE db_owner ADD MEMBER [app.net]
	
	--CRM
	IF NOT EXISTS (SELECT [name]
                FROM [sys].[database_principals]
                WHERE [type] = N'S' AND [name] = N'crm.net')
	Begin
		CREATE USER [crm.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    
	END
	ALTER ROLE db_owner ADD MEMBER [crm.net]
    ALTER USER [crm.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
	
	--SUPORTE
	IF NOT EXISTS (SELECT [name]
                FROM [sys].[database_principals]
                WHERE [type] = N'S' AND [name] = N'suporte.net')
	Begin
		CREATE USER [suporte.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    
	END
	ALTER ROLE db_owner ADD MEMBER [suporte.net]
    ALTER USER [suporte.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';

    --Conversor
	IF NOT EXISTS (SELECT [name]
                FROM [sys].[database_principals]
                WHERE [type] = N'S' AND [name] = N'conversor.net')
	Begin
		CREATE USER [conversor.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    
	END
	ALTER ROLE db_owner ADD MEMBER [conversor.net]
    ALTER USER [conversor.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';

	--Assinaturas Digitais
	IF NOT EXISTS (SELECT [name]
                FROM [sys].[database_principals]
                WHERE [type] = N'S' AND [name] = N'assinaturas-digitais.net')
	Begin
		CREATE USER [assinaturas-digitais.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    
	END
	ALTER ROLE db_owner ADD MEMBER [assinaturas-digitais.net]
    ALTER USER [assinaturas-digitais.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';




