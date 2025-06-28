/*  =========================================================== 
    *  Work item: BUG 14428 
    *  Author: Penhiel
    *  Obs: Seperarando os usuarios, para identificar melhor os problemas de performance
    *   ===========================================================  
    */

--logon
IF NOT EXISTS (
                  SELECT database_principals.name
                    FROM sys.database_principals
                   WHERE
                      database_principals.type = N'S'
                      AND database_principals.name = N'logon.net'
              )
    BEGIN
        CREATE USER [logon.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    END;

ALTER ROLE db_owner ADD MEMBER [logon.net];

--siscont
IF NOT EXISTS (
                  SELECT database_principals.name
                    FROM sys.database_principals
                   WHERE
                      database_principals.type = N'S'
                      AND database_principals.name = N'siscont.net'
              )
    BEGIN
        CREATE USER [siscont.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    END;

ALTER ROLE db_owner ADD MEMBER [siscont.net];

--pcs
IF NOT EXISTS (
                  SELECT database_principals.name
                    FROM sys.database_principals
                   WHERE
                      database_principals.type = N'S'
                      AND database_principals.name = N'pcs.net'
              )
    BEGIN
        CREATE USER [pcs.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    END;

ALTER ROLE db_owner ADD MEMBER [pcs.net];

--agendafinanceira
IF NOT EXISTS (
                  SELECT database_principals.name
                    FROM sys.database_principals
                   WHERE
                      database_principals.type = N'S'
                      AND database_principals.name = N'agendafinanceira.net'
              )
    BEGIN
        CREATE USER [agendafinanceira.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    END;

ALTER ROLE db_owner ADD MEMBER [agendafinanceira.net];

--auditoria
IF NOT EXISTS (
                  SELECT database_principals.name
                    FROM sys.database_principals
                   WHERE
                      database_principals.type = N'S'
                      AND database_principals.name = N'auditoria.net'
              )
    BEGIN
        CREATE USER [auditoria.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    END;

ALTER ROLE db_owner ADD MEMBER [auditoria.net];

--comprascontratos
IF NOT EXISTS (
                  SELECT database_principals.name
                    FROM sys.database_principals
                   WHERE
                      database_principals.type = N'S'
                      AND database_principals.name = N'comprascontratos.net'
              )
    BEGIN
        CREATE USER [comprascontratos.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    END;

ALTER ROLE db_owner ADD MEMBER [comprascontratos.net];

--cursos
IF NOT EXISTS (
                  SELECT database_principals.name
                    FROM sys.database_principals
                   WHERE
                      database_principals.type = N'S'
                      AND database_principals.name = N'cursos.net'
              )
    BEGIN
        CREATE USER [cursos.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    END;

ALTER ROLE db_owner ADD MEMBER [cursos.net];

--gestaoTCU
IF NOT EXISTS (
                  SELECT database_principals.name
                    FROM sys.database_principals
                   WHERE
                      database_principals.type = N'S'
                      AND database_principals.name = N'gestaoTCU.net'
              )
    BEGIN
        CREATE USER [gestaoTCU.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    END;

ALTER ROLE db_owner ADD MEMBER [gestaoTCU.net];

--licitacao
IF NOT EXISTS (
                  SELECT database_principals.name
                    FROM sys.database_principals
                   WHERE
                      database_principals.type = N'S'
                      AND database_principals.name = N'licitacao.net'
              )
    BEGIN
        CREATE USER [licitacao.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    END;

ALTER ROLE db_owner ADD MEMBER [licitacao.net];

--portalTransparencia
IF NOT EXISTS (
                  SELECT database_principals.name
                    FROM sys.database_principals
                   WHERE
                      database_principals.type = N'S'
                      AND database_principals.name = N'portalTransparencia.net'
              )
    BEGIN
        CREATE USER [portalTransparencia.net]
        WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    END;

ALTER ROLE db_owner ADD MEMBER [portalTransparencia.net];

--servicosOnline
IF NOT EXISTS (
                  SELECT database_principals.name
                    FROM sys.database_principals
                   WHERE
                      database_principals.type = N'S'
                      AND database_principals.name = N'servicosOnline.net'
              )
    BEGIN
        CREATE USER [servicosOnline.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    END;

ALTER ROLE db_owner ADD MEMBER [servicosOnline.net];

--sialm
IF NOT EXISTS (
                  SELECT database_principals.name
                    FROM sys.database_principals
                   WHERE
                      database_principals.type = N'S'
                      AND database_principals.name = N'sialm.net'
              )
    BEGIN
        CREATE USER [sialm.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    END;

ALTER ROLE db_owner ADD MEMBER [sialm.net];

--sicaf
IF NOT EXISTS (
                  SELECT database_principals.name
                    FROM sys.database_principals
                   WHERE
                      database_principals.type = N'S'
                      AND database_principals.name = N'siscaf.net'
              )
    BEGIN
        CREATE USER [siscaf.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    END;

ALTER ROLE db_owner ADD MEMBER [siscaf.net];

--sisdoc
IF NOT EXISTS (
                  SELECT database_principals.name
                    FROM sys.database_principals
                   WHERE
                      database_principals.type = N'S'
                      AND database_principals.name = N'sisdoc.net'
              )
    BEGIN
        CREATE USER [sisdoc.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    END;

ALTER ROLE db_owner ADD MEMBER [sisdoc.net];

--sispad
IF NOT EXISTS (
                  SELECT database_principals.name
                    FROM sys.database_principals
                   WHERE
                      database_principals.type = N'S'
                      AND database_principals.name = N'sispad.net'
              )
    BEGIN
        CREATE USER [sispad.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    END;

ALTER ROLE db_owner ADD MEMBER [sispad.net];

--sispat
IF NOT EXISTS (
                  SELECT database_principals.name
                    FROM sys.database_principals
                   WHERE
                      database_principals.type = N'S'
                      AND database_principals.name = N'sispat.net'
              )
    BEGIN
        CREATE USER [sispat.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    END;

ALTER ROLE db_owner ADD MEMBER [sispat.net];

--geral
IF NOT EXISTS (
                  SELECT database_principals.name
                    FROM sys.database_principals
                   WHERE
                      database_principals.type = N'S'
                      AND database_principals.name = N'implanta.net'
              )
    BEGIN
        CREATE USER [implanta.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';
    END;

ALTER USER [implanta.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';

ALTER ROLE db_owner ADD MEMBER [implanta.net];
