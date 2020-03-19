IF(NOT EXISTS (
                  SELECT * FROM sys.sql_logins AS SL WHERE SL.name = 'logon.net'
              )
  )
    BEGIN
        CREATE LOGIN [logon.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';

        CREATE USER [logon.net] FOR LOGIN [logon.net];

        ALTER ROLE db_owner ADD MEMBER [logon.net];
    END;

--siscont
IF(NOT EXISTS (
                  SELECT * FROM sys.sql_logins AS SL WHERE SL.name = 'siscont.net'
              )
  )
    BEGIN
        CREATE LOGIN [siscont.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';

        CREATE USER [siscont.net] FOR LOGIN [siscont.net];

        ALTER ROLE db_owner ADD MEMBER [siscont.net];
    END;

--pcs
IF(NOT EXISTS (SELECT * FROM sys.sql_logins AS SL WHERE SL.name = 'pcs.net'))
    BEGIN
        CREATE LOGIN [pcs.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';

        CREATE USER [pcs.net] FOR LOGIN [pcs.net];

        ALTER ROLE db_owner ADD MEMBER [pcs.net];
    END;

--agendafinanceira
IF(NOT EXISTS (
                  SELECT * FROM sys.sql_logins AS SL WHERE SL.name = 'agendafinanceira.net'
              )
  )
    BEGIN
        CREATE LOGIN [agendafinanceira.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';

        CREATE USER [agendafinanceira.net] FOR LOGIN [agendafinanceira.net];

        ALTER ROLE db_owner ADD MEMBER [agendafinanceira.net];
    END;

--auditoria
IF(NOT EXISTS (
                  SELECT * FROM sys.sql_logins AS SL WHERE SL.name = 'auditoria.net'
              )
  )
    BEGIN
        CREATE LOGIN [auditoria.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';

        CREATE USER [auditoria.net] FOR LOGIN [auditoria.net];

        ALTER ROLE db_owner ADD MEMBER [auditoria.net];
    END;

--comprascontratos
IF(NOT EXISTS (
                  SELECT * FROM sys.sql_logins AS SL WHERE SL.name = 'comprascontratos.net'
              )
  )
    BEGIN
        CREATE LOGIN [comprascontratos.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';

        CREATE USER [comprascontratos.net] FOR LOGIN [comprascontratos.net];

        ALTER ROLE db_owner ADD MEMBER [comprascontratos.net];
    END;

--cursos
IF(NOT EXISTS (
                  SELECT * FROM sys.sql_logins AS SL WHERE SL.name = 'cursos.net'
              )
  )
    BEGIN
        CREATE LOGIN [cursos.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';

        CREATE USER [cursos.net] FOR LOGIN [cursos.net];

        ALTER ROLE db_owner ADD MEMBER [cursos.net];
    END;

--gestaoTCU
IF(NOT EXISTS (
                  SELECT * FROM sys.sql_logins AS SL WHERE SL.name = 'gestaoTCU.net'
              )
  )
    BEGIN
        CREATE LOGIN [gestaoTCU.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';

        CREATE USER [gestaoTCU.net] FOR LOGIN [gestaoTCU.net];

        ALTER ROLE db_owner ADD MEMBER [gestaoTCU.net];
    END;

--licitacao
IF(NOT EXISTS (
                  SELECT * FROM sys.sql_logins AS SL WHERE SL.name = 'licitacao.net'
              )
  )
    BEGIN
        CREATE LOGIN [licitacao.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';

        CREATE USER [licitacao.net] FOR LOGIN [licitacao.net];

        ALTER ROLE db_owner ADD MEMBER [licitacao.net];
    END;

--portalTransparencia
IF(NOT EXISTS (
                  SELECT *
                    FROM sys.sql_logins AS SL
                   WHERE
                      SL.name = 'portalTransparencia.net'
              )
  )
    BEGIN
        CREATE LOGIN [portalTransparencia.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';

        CREATE USER [portalTransparencia.net] FOR LOGIN [portalTransparencia.net];

        ALTER ROLE db_owner ADD MEMBER [portalTransparencia.net];
    END;

--portalTransparencia
IF(NOT EXISTS (
                  SELECT * FROM sys.sql_logins AS SL WHERE SL.name = 'servicosOnline.net'
              )
  )
    BEGIN
        CREATE LOGIN [servicosOnline.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';

        CREATE USER [servicosOnline.net] FOR LOGIN [servicosOnline.net];

        ALTER ROLE db_owner ADD MEMBER [servicosOnline.net];
    END;

--sialm
IF(NOT EXISTS (
                  SELECT * FROM sys.sql_logins AS SL WHERE SL.name = 'sialm.net'
              )
  )
    BEGIN
        CREATE LOGIN [sialm.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';

        CREATE USER [sialm.net] FOR LOGIN [sialm.net];

        ALTER ROLE db_owner ADD MEMBER [sialm.net];
    END;

--siscaf.net
IF(NOT EXISTS (
                  SELECT * FROM sys.sql_logins AS SL WHERE SL.name = 'siscaf.net'
              )
  )
    BEGIN
        CREATE LOGIN [siscaf.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';

        CREATE USER [siscaf.net] FOR LOGIN [siscaf.net];

        ALTER ROLE db_owner ADD MEMBER [siscaf.net];
    END;

--sisdoc.net
IF(NOT EXISTS (
                  SELECT * FROM sys.sql_logins AS SL WHERE SL.name = 'sisdoc.net'
              )
  )
    BEGIN
        CREATE LOGIN [sisdoc.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';

        CREATE USER [sisdoc.net] FOR LOGIN [sisdoc.net];

        ALTER ROLE db_owner ADD MEMBER [sisdoc.net];
    END;

--sispad
IF(NOT EXISTS (
                  SELECT * FROM sys.sql_logins AS SL WHERE SL.name = 'sispad.net'
              )
  )
    BEGIN
        CREATE LOGIN [sispad.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';

        CREATE USER [sispad.net] FOR LOGIN [sispad.net];

        ALTER ROLE db_owner ADD MEMBER [sispad.net];
    END;

--sispat
IF(NOT EXISTS (
                  SELECT * FROM sys.sql_logins AS SL WHERE SL.name = 'sispat.net'
              )
  )
    BEGIN
        CREATE LOGIN [sispat.net] WITH PASSWORD = 'M@st3rP0w3r@zur3Prd';

        CREATE USER [sispat.net] FOR LOGIN [sispat.net];

        ALTER ROLE db_owner ADD MEMBER [sispat.net];
    END;
