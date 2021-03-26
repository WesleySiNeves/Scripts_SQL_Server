



SET ANSI_NULLS ON;

DECLARE @Padrao VARCHAR(30) = 'NÃO IDENTIFICADO';

IF(NOT EXISTS (SELECT * FROM sys.schemas AS S WHERE S.name = 'ElmahDW'))
    BEGIN
        DECLARE @CreateSchema VARCHAR(100) = 'CREATE SCHEMA ElmahDW';

        EXEC(@CreateSchema);
    END;

	

IF(NOT EXISTS (SELECT * FROM sys.schemas AS S WHERE S.name = 'Staging'))
    BEGIN
        DECLARE @CreateSchema_Staging VARCHAR(100) = 'CREATE SCHEMA Staging';

        EXEC(@CreateSchema_Staging);
    END;


	

--CREATE TABLE Staging.ELMAH_Error
--(
--    [ErrorId]     UNIQUEIDENTIFIER PRIMARY KEY CLUSTERED(ErrorId),
--    [Application] VARCHAR(60),
--    [Host]        VARCHAR(50),
--    [Type]        VARCHAR(100),
--    [Source]      VARCHAR(60),
--    [Message]     VARCHAR(500),
--    [User]        VARCHAR(50),
--    [StatusCode]  INT,
--    [TimeUtc]     DATETIME2(2),
--    [AllXml]     XML,
--    ServerName   VARCHAR(60)
--);
	


DROP TABLE IF EXISTS ElmahDW.FatoElmah;
DROP TABLE IF EXISTS ElmahDW.DimAplication;
DROP TABLE IF EXISTS ElmahDW.DimHost;
DROP TABLE IF EXISTS ElmahDW.DimSources;
DROP TABLE IF EXISTS ElmahDW.DimStatusErros;
DROP TABLE IF EXISTS ElmahDW.DimTypeErros;
DROP TABLE IF EXISTS ElmahDW.DimUsers;
DROP TABLE IF EXISTS ElmahDW.DimTempo;
DROP TABLE IF EXISTS ElmahDW.DimClientes;
DROP TABLE IF EXISTS ElmahDW.DimEstados;
DROP TABLE IF EXISTS ElmahDW.DimUrlErros;




/****** Script for SelectTopNRows command from SSMS  ******/
IF(NOT EXISTS (SELECT * FROM sys.tables AS T WHERE T.name = 'DimUrlError'))
    BEGIN
        CREATE TABLE ElmahDW.DimUrlError
        (
            SkDimUrlError INT NOT NULL PRIMARY KEY IDENTITY(0, 1),
            Url      VARCHAR(200)
        );
    END;


/****** Script for SelectTopNRows command from SSMS  ******/
IF(NOT EXISTS (SELECT * FROM sys.tables AS T WHERE T.name = 'DimEstados'))
    BEGIN
        CREATE TABLE ElmahDW.DimEstados
        (
            SkDimEstado TINYINT NOT NULL PRIMARY KEY IDENTITY(0, 1),
            Sigla       CHAR(2) NOT NULL,
            Estado      VARCHAR(40),
			Regiao VARCHAR(20)
        );
    END;


	
/****** Script for SelectTopNRows command from SSMS  ******/
IF(NOT EXISTS (SELECT * FROM sys.tables AS T WHERE T.name = 'DimClientes'))
    BEGIN
        CREATE TABLE ElmahDW.DimClientes
        (
            SkDimCliente SMALLINT NOT NULL PRIMARY KEY IDENTITY(0, 1),
            Cliente      VARCHAR(50),
			Sigla VARCHAR(10),
			Categoria VARCHAR(8)
        );
    END;

IF(NOT EXISTS (SELECT * FROM sys.tables AS T WHERE T.name = 'DimHost'))
    BEGIN
        CREATE TABLE ElmahDW.DimHost
        (
            SkDimHost TINYINT NOT NULL PRIMARY KEY IDENTITY(0, 1),
            Host      VARCHAR(30)
        );
    END;

IF(NOT EXISTS (SELECT * FROM sys.tables AS T WHERE T.name = 'DimAplication'))
    BEGIN
        CREATE TABLE ElmahDW.DimAplication
        (
            SkDimAplication TINYINT NOT NULL PRIMARY KEY IDENTITY(0, 1),
            Aplication      VARCHAR(30)
        );
    END;

IF(NOT EXISTS (SELECT * FROM sys.tables AS T WHERE T.name = 'DimTypeErros'))
    BEGIN
        CREATE TABLE ElmahDW.DimTypeErros
        (
            SkDimTypeError SMALLINT NOT NULL PRIMARY KEY IDENTITY(0, 1),
            Error          VARCHAR(110)
        );
    END;

IF(NOT EXISTS (SELECT * FROM sys.tables AS T WHERE T.name = 'DimSources'))
    BEGIN
        CREATE TABLE ElmahDW.DimSources
        (
            SkDimSource SMALLINT NOT NULL PRIMARY KEY IDENTITY(0, 1),
            Source      VARCHAR(80)
        );
    END;

IF(NOT EXISTS (
                  SELECT * FROM sys.tables AS T WHERE T.name = 'DimStatusErros'
              )
  )
    BEGIN
        CREATE TABLE ElmahDW.DimStatusErros
        (
            SkDimStatusError SMALLINT NOT NULL PRIMARY KEY IDENTITY(0, 1),
            Status           SMALLINT
        );
    END;

IF(NOT EXISTS (SELECT * FROM sys.tables AS T WHERE T.name = 'DimUsers'))
    BEGIN
        CREATE TABLE ElmahDW.DimUsers
        (
            SkUser  INT NOT NULL PRIMARY KEY IDENTITY(0, 1),
            Usuario VARCHAR(100)
        );
    END;


IF(NOT EXISTS (SELECT * FROM sys.tables AS T WHERE T.name = 'DimTempo'))
    BEGIN
		CREATE TABLE ElmahDW.DimTempo
		(
			SK_DimTempo INT      NOT NULL PRIMARY KEY IDENTITY(0, 1),
			Dia         DATE     NOT NULL,
			DiaExtenso VARCHAR(20) NOT NULL DEFAULT (''),
			Mes         TINYINT  NOT NULL,
			Ano         SMALLINT NOT NULL
		);
    END;



IF(NOT EXISTS (
                  SELECT * FROM ElmahDW.DimTempo AS DT WHERE DT.SK_DimTempo = 0
              )
  )
    BEGIN
        INSERT INTO ElmahDW.DimTempo(
                                        Dia,
                                        Mes,
                                        Ano
                                    )
        VALUES(DATEFROMPARTS(1900, 1, 1), MONTH(DATEFROMPARTS(1900, 1, 1)), YEAR(DATEFROMPARTS(1900, 1, 1)));
    END;
IF(NOT EXISTS (
                  SELECT * FROM ElmahDW.DimHost AS DH WHERE DH.Host = 'NÃO IDENTIFICADO'
              )
  )
    BEGIN
        INSERT INTO ElmahDW.DimHost(
                                       Host
                                   )
        VALUES('NÃO IDENTIFICADO' -- Host - varchar(30)
              );
    END;

INSERT INTO ElmahDW.DimHost(
                               Host
                           )
SELECT DISTINCT UPPER(EE.Host)
  FROM Staging.ELMAH_Error AS EE
 WHERE
    LEN(EE.Host) > 0
    AND NOT EXISTS (
                       SELECT *
                         FROM ElmahDW.DimHost AS DH
                        WHERE
                           EE.Host COLLATE DATABASE_DEFAULT = DH.Host
                   );

IF(NOT EXISTS (
                  SELECT *
                    FROM ElmahDW.DimAplication AS DA
                   WHERE
                      DA.Aplication = 'NÃO IDENTIFICADO'
              )
  )
    BEGIN
        INSERT INTO ElmahDW.DimAplication(
                                             Aplication
                                         )
        VALUES('NÃO IDENTIFICADO' -- Aplication - varchar(30)
              );
    END;

INSERT INTO ElmahDW.DimAplication(
                                     Aplication
                                 )
SELECT DISTINCT EE.Application
  FROM Staging.ELMAH_Error AS EE
 WHERE
    LEN(EE.Application) > 0
    AND NOT EXISTS (
                       SELECT *
                         FROM ElmahDW.DimAplication AS DA
                        WHERE
                           DA.Aplication COLLATE DATABASE_DEFAULT = EE.Application
                   );

IF(NOT EXISTS (
                  SELECT *
                    FROM ElmahDW.DimTypeErros AS DA
                   WHERE
                      DA.Error = 'NÃO IDENTIFICADO'
              )
  )
    BEGIN
        INSERT INTO ElmahDW.DimTypeErros(
                                            Error
                                        )
        VALUES('NÃO IDENTIFICADO' -- Aplication - varchar(30)
              );
    END;

INSERT INTO ElmahDW.DimTypeErros(
                                    Error
                                )
SELECT DISTINCT EE.Type
  FROM Staging.ELMAH_Error AS EE
 WHERE
    LEN(EE.Application) > 0
    AND EE.Type NOT IN ('Info')
    AND NOT EXISTS (
                       SELECT *
                         FROM ElmahDW.DimTypeErros AS DA
                        WHERE
                           DA.Error COLLATE DATABASE_DEFAULT = EE.Type
                   );



IF(NOT EXISTS (
                  SELECT *
                    FROM ElmahDW.DimSources AS DA
                   WHERE
                      DA.Source = 'NÃO IDENTIFICADO'
              )
  )
    BEGIN
        INSERT INTO ElmahDW.DimSources(
                                          Source
                                      )
        VALUES('NÃO IDENTIFICADO' -- Aplication - varchar(30)
              );
    END;

INSERT INTO ElmahDW.DimSources(
                                  Source
                              )
SELECT DISTINCT EE.Source
  FROM Staging.ELMAH_Error AS EE
 WHERE
    LEN(EE.Source) > 0
    AND NOT EXISTS (
                       SELECT *
                         FROM ElmahDW.DimSources AS DS
                        WHERE
                           DS.Source COLLATE DATABASE_DEFAULT = EE.Source
                   );

IF(NOT EXISTS (
                  SELECT * FROM ElmahDW.DimStatusErros AS DSE WHERE DSE.Status = -7
              )
  )
    BEGIN
        INSERT INTO ElmahDW.DimStatusErros(
                                              Status
                                          )
        VALUES(-7 -- Aplication - varchar(30)
              );
    END;

INSERT INTO ElmahDW.DimStatusErros(
                                      Status
                                  )
SELECT DISTINCT EE.StatusCode
  FROM Staging.ELMAH_Error AS EE
 WHERE
    LEN(EE.StatusCode) > 0
    AND NOT EXISTS (
                       SELECT *
                         FROM ElmahDW.DimStatusErros AS DSE
                        WHERE
                           DSE.Status = EE.StatusCode
                   );

IF(NOT EXISTS (
                  SELECT * FROM ElmahDW.DimUsers AS DA WHERE DA.Usuario = 'NÃO IDENTIFICADO'
              )
  )
    BEGIN
        INSERT INTO ElmahDW.DimUsers(
                                        Usuario
                                    )
        VALUES('NÃO IDENTIFICADO' -- Aplication - varchar(30)
              );
    END;

INSERT INTO ElmahDW.DimUsers(
                                Usuario
                            )
SELECT DISTINCT EE.[User]
  FROM Staging.ELMAH_Error AS EE
 WHERE
    LEN(LTRIM(RTRIM(EE.[User]))) > 0
    AND EE.[User] <> ''
    AND NOT EXISTS (
                       SELECT *
                         FROM ElmahDW.DimUsers AS DU
                        WHERE
                           DU.Usuario COLLATE DATABASE_DEFAULT = EE.[User]
                   );




DECLARE @inicio DATE = (
                           SELECT CAST(MIN(EE.TimeUtc) AS DATE)FROM Staging.ELMAH_Error AS EE
                       );
DECLARE @termino DATE = DATEADD(YEAR, 10, @inicio);

WHILE(@inicio <= @termino)
    BEGIN
        INSERT INTO ElmahDW.DimTempo(
                                        Dia,
                                        Mes,
                                        Ano
                                    )
        SELECT @inicio, MONTH(@inicio), YEAR(@inicio);

        SET @inicio = DATEADD(DAY, 1, @inicio);
    END;


UPDATE target
   SET target.DiaExtenso = CASE DATEPART(WEEKDAY, Dia)WHEN 7 THEN 'Sábado'
                           WHEN 6 THEN 'Sexta-feira'
                           WHEN 5 THEN 'Quinta-feira'
                           WHEN 4 THEN 'Quarta-feira'
                           WHEN 3 THEN 'Terça-feira'
                           WHEN 2 THEN 'Segunda-feira'
                           WHEN 1 THEN 'Domingo' END
  FROM ElmahDW.DimTempo AS target



INSERT INTO ElmahDW.DimEstados(
                                  Sigla,
                                  Estado,
								  Regiao
                              )
VALUES('--', 'Não Informado','Não Informado'),
('RO', 'Rondônia','Norte'),
('AC', 'Acre','Norte'),
('AM', 'Amazonas','Norte'),
('RR', 'Roraima','Norte'),
('PA', 'Pará','Norte'),
('AP', 'Amapá','Norte'),
('TO', 'Tocantins','Norte'),
('MA', 'Maranhão','Nordeste'),
('PI', 'Piauí','Nordeste'),
('CE', 'Ceará','Nordeste'),
('RN', 'Rio Grande do Norte','Nordeste'),
('PB', 'Paraíba','Nordeste'),
('PE', 'Pernambuco','Nordeste'),
('AL', 'Alagoas','Nordeste'),
('SE', 'Sergipe','Nordeste'),
('BA', 'Bahia','Nordeste'),
('MG', 'Minas Gerais','Sudeste'),
('ES', 'Espírito Santo','Sudeste'),
('RJ', 'Rio de Janeiro','Sudeste'),
('SP', 'São Paulo','Sudeste'),
('PR', 'Paraná','Sul'),
('SC', 'Santa Catarina','Sul'),
('RS', 'Rio Grande do Sul','Sul'),
('MS', 'Mato Grosso do Sul','Centro-Oeste'),
('MT', 'Mato Grosso','Centro-Oeste'),
('GO', 'Goiás','Centro-Oeste'),
('DF', 'Distrito Federal','Centro-Oeste'),
('BR', 'BRASIL','BRASIL');



--SELECT * FROM ElmahDW.DimTempo AS DT
--SELECT * FROM ElmahDW.DimAplication AS DA
--SELECT * FROM ElmahDW.DimHost AS DH
--SELECT * FROM ElmahDW.DimSources AS DS
--SELECT * FROM ElmahDW.DimStatusErros AS DSE
--SELECT * FROM ElmahDW.DimTypesErros AS DTE
--SELECT * FROM ElmahDW.DimUsers AS DU
--SELECT DC.SkDimCliente, DC.Cliente FROM ElmahDW.DimClientes AS DC
--SELECT * FROM  ElmahDW.DimEstados AS DE




CREATE TABLE ElmahDW.FatoElmah
(
    SK_DimTempo      INT      NOT NULL CONSTRAINT FK_ElmahDWFatoElmah_TO_ElmahDWDimTempo REFERENCES ElmahDW.DimTempo(SK_DimTempo),
    SkDimAplication  TINYINT  NOT NULL CONSTRAINT FK_ElmahDWFatoElmah_TO_ElmahDWDimAplication REFERENCES ElmahDW.DimAplication(SkDimAplication),
    SkDimHost        TINYINT  NOT NULL CONSTRAINT FK_ElmahDWFatoElmah_TO_ElmahDWDimHost REFERENCES ElmahDW.DimHost(SkDimHost),
    SkDimSource      SMALLINT NOT NULL CONSTRAINT FK_ElmahDWFatoElmah_TO_ElmahDWDimSource REFERENCES ElmahDW.DimSources(SkDimSource),
    SkDimStatusError SMALLINT NOT NULL CONSTRAINT FK_ElmahDWFatoElmah_TO_ElmahDWDimStatusError REFERENCES ElmahDW.DimStatusErros(SkDimStatusError),
    SkUser           INT NOT NULL CONSTRAINT FK_ElmahDWFatoElmah_TO_ElmahDWDimUser REFERENCES ElmahDW.DimUsers(SkUser),
    SkDimCliente     SMALLINT NOT NULL CONSTRAINT FK_ElmahDWFatoElmah_TO_ElmahDimClientes REFERENCES ElmahDW.DimClientes(SkDimCliente),
    SkDimTypesError  SMALLINT NOT NULL CONSTRAINT FK_ElmahDWFatoElmah_TO_ElmahDimTypeError REFERENCES ElmahDW.DimTypeErros(SkDimTypeError),
    SkDimEstado      TINYINT  NOT NULL CONSTRAINT FK_ElmahDWFatoElmah_TO_ElmahDimEstados REFERENCES ElmahDW.DimEstados(SkDimEstado),
    Quantidade       INT,
    CONSTRAINT PK_FatoElmah PRIMARY KEY CLUSTERED(SK_DimTempo, SkDimAplication, SkDimHost, SkDimSource, SkDimStatusError, SkUser, SkDimCliente, SkDimTypesError, SkDimEstado)
)
WITH (DATA_COMPRESSION = PAGE);

IF(OBJECT_ID('TEMPDB..#Dados') IS NOT NULL)
    DROP TABLE #Dados;

CREATE TABLE #Dados
(
    [Application] VARCHAR(60),
    [Host]        VARCHAR(50),
    [Type]        VARCHAR(100),
    [Source]      VARCHAR(60),
    [User]        VARCHAR(50),
    [StatusCode]  SMALLINT,
    [TimeUtc]     DATE,
    ServerName    VARCHAR(100),
	--URL VARCHAR(1000),
	Sigla CHAR(2)
   

);






CREATE NONCLUSTERED INDEX #IX_TimeUtc ON #Dados([TimeUtc]);


INSERT INTO #Dados(
                      Application,
                      Host,
                      Type,
                      Source,
                      [User],
                      StatusCode,
                      TimeUtc,
                      ServerName
                      --URL
                  )
SELECT EE.Application,
       EE.Host,
       EE.Type,
       EE.Source,
       EE.[User],
       EE.StatusCode,
       EE.TimeUtc,
       EE.ServerName
      -- PaginaErro = REPLACE(EE.AllXml.value('(/error/serverVariables/item[@name="PATH_TRANSLATED"]/value/@string)[1]', 'nvarchar(max)'), 'C:\inetpub\wwwroot\', '')
  FROM Staging.ELMAH_Error AS EE;


DELETE D FROM #Dados AS D WHERE D.ServerName IS NULL;





-- Get Sigla Estados

UPDATE D SET D.Sigla =SUBSTRING(D.ServerName, CHARINDEX('-', D.ServerName) + 1, 2) FROM #Dados AS D



IF(NOT EXISTS (
                  SELECT * FROM ElmahDW.DimClientes AS DC WHERE DC.SkDimCliente = 0
              )
  )
    BEGIN
        INSERT INTO ElmahDW.DimClientes(
                                           Cliente
                                       )
        VALUES('NÃO IDENTIFICADO' -- Cliente - varchar(30)
              );
    END;
	


INSERT INTO ElmahDW.DimClientes(
                                   Cliente,
								   Sigla,
								   Categoria
                               )
SELECT DISTINCT D.ServerName,REPLACE(D.ServerName,'.implanta.net.br','') AS Sigla, UPPER(LEFT(D.ServerName,CHARINDEX('-',D.ServerName) -1)) AS Categoria
  FROM #Dados AS D
 WHERE
    NOT EXISTS (
                   SELECT * FROM ElmahDW.DimClientes AS DC WHERE DC.Cliente = D.ServerName
               );



UPDATE target
   SET target.Host = UPPER(Host),
	   target.Sigla = UPPER(Sigla)
  FROM #Dados AS target;

  

UPDATE target
   SET target.Host = 'NÃO IDENTIFICADO'
  FROM #Dados target
 WHERE
    RTRIM(LTRIM(target.Host)) = '';

UPDATE target
   SET target.Type = 'NÃO IDENTIFICADO'
  FROM #Dados target
 WHERE
    RTRIM(LTRIM(target.Type)) = '';

UPDATE target
   SET target.Source = 'NÃO IDENTIFICADO'
  FROM #Dados target
 WHERE
    RTRIM(LTRIM(target.Source)) = '';

UPDATE target
   SET target.[User] = 'NÃO IDENTIFICADO'
  FROM #Dados target
 WHERE
    RTRIM(LTRIM(target.[User])) = '';


UPDATE #Dados SET Sigla ='DF' WHERE ServerName  LIKE '%CONVERSAO%'


;WITH ETL_GetSkDimTempo
    AS
    (
        SELECT DT.Dia,
               DT.SK_DimTempo,
               COUNT(1) Total
          FROM #Dados AS D
               JOIN ElmahDW.DimTempo AS DT ON D.TimeUtc = DT.Dia
         GROUP BY
            DT.Dia,
            DT.SK_DimTempo
    ),
     ETL_GetSKDimAplication
    AS
    (
        SELECT DA.Aplication,
               DA.SkDimAplication,
               COUNT(1) Total
          FROM #Dados AS D
               JOIN ElmahDW.DimAplication AS DA ON D.Application = DA.Aplication
         GROUP BY
            DA.Aplication,
            DA.SkDimAplication
    ),
     ETL_GetSKDimHost
    AS
    (
        SELECT DA.Host,
               DA.SkDimHost,
               COUNT(1) Total
          FROM #Dados AS D
               LEFT JOIN ElmahDW.DimHost AS DA ON D.Host = DA.Host
         GROUP BY
            DA.Host,
            DA.SkDimHost
    ),
     ETL_GetSKDimSources
    AS
    (
        SELECT DA.Source,
               DA.SkDimSource,
               COUNT(1) Total
          FROM #Dados AS D
               LEFT JOIN ElmahDW.DimSources AS DA ON D.Source = DA.Source
         GROUP BY
            DA.Source,
            DA.SkDimSource
    ),
     ETL_GetSKDimStatusErros
    AS
    (
        SELECT DA.Status,
               DA.SkDimStatusError,
               COUNT(1) Total
          FROM #Dados AS D
               LEFT JOIN ElmahDW.DimStatusErros AS DA ON D.StatusCode = DA.Status
         GROUP BY
            DA.Status,
            DA.SkDimStatusError
    ),
     ETL_GetSKDimUsers
    AS
    (
        SELECT DA.Usuario,
               DA.SkUser,
               COUNT(1) Total
          FROM #Dados AS D
               LEFT JOIN ElmahDW.DimUsers AS DA ON D.[User] = DA.Usuario
         GROUP BY
            DA.Usuario,
            DA.SkUser
    ),
     ETL_GetSKDimClientes
    AS
    (
        SELECT DA.Cliente,
               DA.SkDimCliente,
               COUNT(1) Total
          FROM #Dados AS D
               JOIN ElmahDW.DimClientes AS DA ON D.ServerName = DA.Cliente
         GROUP BY
            DA.Cliente,
            DA.SkDimCliente
    ),
     ETL_GetSKDimEstados
    AS
    (
        SELECT DE.SkDimEstado,
               DE.Sigla,
               COUNT(1) Total
          FROM #Dados AS D
               JOIN ElmahDW.DimEstados AS DE ON DE.Sigla = D.Sigla
         GROUP BY
            DE.SkDimEstado,
            DE.Sigla
    ),
     ETL_GetSKDimTypeErros
    AS
    (
        SELECT DTE.SkDimTypeError,
               DTE.Error,
               COUNT(1) Total
          FROM #Dados AS D
               JOIN ElmahDW.DimTypeErros AS DTE ON D.Type = DTE.Error
         GROUP BY
            DTE.SkDimTypeError,
            DTE.Error
    )


INSERT INTO ElmahDW.FatoElmah(
                                 SK_DimTempo,
                                 SkDimAplication,
                                 SkDimHost,
                                 SkDimSource,
                                 SkDimStatusError,
                                 SkUser,
                                 SkDimCliente,
                                 SkDimTypesError,
								 SkDimEstado,
                                 Quantidade
                             )
SELECT tempo.SK_DimTempo,
       apli.SkDimAplication,
       host.SkDimHost,
       sour.SkDimSource,
       error.SkDimStatusError,
       users.SkUser,
       cli.SkDimCliente,
       tyerro.SkDimTypeError,
       estado.SkDimEstado,
       COUNT(1) Quantidade
  FROM #Dados AS source
       LEFT JOIN ETL_GetSkDimTempo tempo ON source.TimeUtc = tempo.Dia
       LEFT JOIN ETL_GetSKDimAplication apli ON source.Application = apli.Aplication
       LEFT JOIN ETL_GetSKDimHost host ON host.Host = source.Host
       LEFT JOIN ETL_GetSKDimSources sour ON sour.Source = source.Source
       LEFT JOIN ETL_GetSKDimStatusErros error ON error.Status = source.StatusCode
       LEFT JOIN ETL_GetSKDimUsers users ON users.Usuario = source.[User]
       LEFT JOIN ETL_GetSKDimClientes cli ON cli.Cliente = source.ServerName
       LEFT JOIN ETL_GetSKDimTypeErros tyerro ON tyerro.Error = source.Type
       LEFT JOIN ETL_GetSKDimEstados estado ON estado.Sigla = source.Sigla
	
	   WHERE  estado.SkDimEstado IS NOT NULL
 GROUP BY
    tempo.Dia,
    tempo.SK_DimTempo,
    apli.SkDimAplication,
    host.SkDimHost,
    sour.SkDimSource,
    error.SkDimStatusError,
    users.SkUser,
    cli.SkDimCliente,
    tyerro.SkDimTypeError,
    estado.SkDimEstado;
	

	
	SELECT
		   --FE.SK_DimTempo,
   		--   FE.SkDimEstado,
     --      FE.SkDimAplication,
		   --FE.SkDimCliente,
           --FE.SkDimHost,
           --FE.SkDimSource,
         --  FE.SkDimStatusError,
           FE.SkUser,
           FE.SkDimTypesError,
           
           FE.Quantidade FROM  ElmahDW.FatoElmah AS FE
	
/*
Função para retornas os erros do banco
*/

GO

--SELECT COUNT(1) FROM Staging.ELMAH_Error AS EE WITH(NOLOCK)




--CREATE OR ALTER PROCEDURE dbo.GetElmahErrosOnAplication
--AS
--    BEGIN
--IF(EXISTS (SELECT * FROM sys.tables AS T WHERE T.name = 'ELMAH_Error'))
--    BEGIN
--        WITH Dados
--            AS
--            (
--                SELECT EE.ErrorId,
--                       EE.Application,
--                       EE.Host,
--                       EE.Type,
--                       EE.Source,
--                       EE.Message,
--                       EE.[User],
--                       EE.StatusCode,
--                       EE.TimeUtc,
--                       SERVER_NAME = DB_NAME(),
--                       EE.AllXml
--                  FROM Staging.ELMAH_Error AS EE
--                 WHERE
--                    EE.Type <> 'Info'
--            )
--        SELECT R.ErrorId,
--               R.Application,
--               R.Host,
--               R.Type,
--               R.Source,
--               R.Message,
--               R.[User],
--               R.StatusCode,
--               R.TimeUtc,
--               R.AllXml,
--			   R.SERVER_NAME
--          FROM Dados R
--         WHERE
--            R.SERVER_NAME IS NOT NULL;
--    END;
--ELSE
--    BEGIN
--        DROP TABLE IF EXISTS #retorno;

--        CREATE TABLE #retorno
--        (
--            [ErrorId]     UNIQUEIDENTIFIER,
--            [Application] VARCHAR(60),
--            [Host]        VARCHAR(50),
--            [Type]        VARCHAR(100),
--            [Source]      VARCHAR(60),
--            [Message]     VARCHAR(500),
--            [User]        VARCHAR(50),
--            [StatusCode]  INT,
--            [TimeUtc]     DATETIME,
--            [AllXml]      VARCHAR(MAX),
--			SERVER_NAME  VARCHAR(40)
--        );

--        SELECT * FROM #retorno AS R;
--    END;
--END;



	
SELECT  TOP 1000
--EE.ErrorId,
      -- EE.Application,
      -- EE.Host,
       EE.Type,
       EE.Source,
       EE.Message,
       --EE.[User],
       --EE.StatusCode,
       --EE.TimeUtc,
       --EE.AllXml,
       --EE.ServerName,
	     HTTP_ORIGIN = CAST(EE.AllXml AS XML).value('(/error/serverVariables/item[@name="HTTP_ORIGIN"]/value/@string)[1]', 'nvarchar(max)')
     	 FROM Staging.ELMAH_Error AS EE
		-- WHERE EE.Type ='Microsoft.ReportingServices.ReportProcessing.ReportProcessingException'
	




--;WITH Dados
--   AS (SELECT EE.Type,
--              CAST(EE.AllXml AS XML) XML
--       FROM Staging.ELMAH_Error AS EE
--       WHERE EE.Type NOT IN ( 'Info' )
--      )
--SELECT R.XML,
--       REMOTE_HOST = XML.value('(/error/serverVariables/item[@name="REMOTE_HOST"]/value/@string)[1]', 'nvarchar(30)'),
--       HTTP_REFERER = XML.value('(/error/serverVariables/item[@name="HTTP_REFERER"]/value/@string)[1]', 'nvarchar(max)'),
--       HTTP_USER_AGENT = XML.value(
--                                      '(/error/serverVariables/item[@name="HTTP_USER_AGENT"]/value/@string)[1]',
--                                      'nvarchar(max)'
--                                  ),
--       HTTP_ORIGIN = XML.value('(/error/serverVariables/item[@name="HTTP_ORIGIN"]/value/@string)[1]', 'nvarchar(max)'),
--       APPL_PHYSICAL_PATH = XML.value(
--                                         '(/error/serverVariables/item[@name="APPL_PHYSICAL_PATH"]/value/@string)[1]',
--                                         'nvarchar(max)'
--                                     ),
--       SERVER_NAME = XML.value('(/error/serverVariables/item[@name="SERVER_NAME"]/value/@string)[1]', 'nvarchar(max)')
--FROM Dados R
--WHERE R.Type = 'System.Data.SqlClient.SqlException';



SELECT * FROM ElmahDW.FatoElmah AS FE

SELECT * FROM ElmahDW.DimAplication AS DA
SELECT * FROM ElmahDW.DimClientes AS DC
SELECT * FROM ElmahDW.DimHost AS DH
SELECT * FROM ElmahDW.DimStatusErros AS DSE
SELECT * FROM ElmahDW.DimTempo AS DT
SELECT * FROM ElmahDW.DimTypeErros AS DTE