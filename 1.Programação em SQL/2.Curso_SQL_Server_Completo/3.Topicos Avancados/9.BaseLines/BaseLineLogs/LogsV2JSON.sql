

IF (EXISTS (SELECT * FROM sys.tables AS T WHERE T.name = 'LogsJSON'))
BEGIN
    DROP TABLE Log.LogsJSON;

END;




IF (EXISTS
(
    SELECT *
    FROM sys.sequences AS S
    WHERE S.name = 'SEQ_LogsJSON'
)
   )
BEGIN

    DROP SEQUENCE dbo.SEQ_LogsJSON;
END;

IF (EXISTS
(
    SELECT *
    FROM sys.default_constraints AS DC
    WHERE DC.name = 'DEF_SistemasEspelhamentoLogs'
)
   )
BEGIN

    ALTER TABLE Sistema.SistemasEspelhamentoLogs
    DROP CONSTRAINT DEF_SistemasEspelhamentoLogs;
END;

IF (EXISTS
(
    SELECT *
    FROM sys.sequences AS S
    WHERE S.name = 'Seq_SistemasEspelhamentoLogs'
)
   )
BEGIN


    DROP SEQUENCE Sistema.Seq_SistemasEspelhamentoLogs;
END;


IF (NOT EXISTS
(
    SELECT *
    FROM sys.tables AS T
    WHERE T.name = 'SistemasEspelhamentoLogs'
)
   )
BEGIN



    CREATE SEQUENCE Sistema.Seq_SistemasEspelhamentoLogs
    AS TINYINT
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    NO CYCLE
    NO CACHE;



    CREATE TABLE Sistema.SistemasEspelhamentoLogs
    (
        IdSistema TINYINT,
        Codsistema UNIQUEIDENTIFIER NOT NULL,
        NomeSistema VARCHAR(100),
        Descricao VARCHAR(200)
            CONSTRAINT PK_SistemasEspelhamentoLogs
            PRIMARY KEY (IdSistema),
        CONSTRAINT Unique_SistemasEspelhamentoLogsCodsistema
            UNIQUE (Codsistema),
        CONSTRAINT FK_SistemasEspelhamentoLogsCodsistema
                FOREIGN KEY (Codsistema)
                REFERENCES Sistema.Sistemas (CodSistema)
    );

    ALTER TABLE Sistema.SistemasEspelhamentoLogs
    ADD CONSTRAINT DEF_SistemasEspelhamentoLogs
        DEFAULT (NEXT VALUE FOR Sistema.Seq_SistemasEspelhamentoLogs) FOR IdSistema;

    INSERT INTO Sistema.SistemasEspelhamentoLogs
    (
        Codsistema,
        NomeSistema,
        Descricao
    )
    SELECT S.CodSistema,
           S.Nome,
           S.Descricao
    FROM Sistema.Sistemas AS S;


END;





/* ==================================================================
--Data: 17/01/2019 
--Autor :Wesley Neves
--Observação:  Criação da tabela Logs Em JSON
 
-- ==================================================================
*/
IF (EXISTS
(
    SELECT *
    FROM sys.default_constraints AS DC
    WHERE DC.name = 'Seq_LogLogsJSON'
)
   )
BEGIN

    ALTER TABLE Log.LogsJSON DROP CONSTRAINT Seq_LogLogsJSON;
END;

IF (EXISTS
(
    SELECT *
    FROM sys.sequences AS S
    WHERE S.name = 'Seq_LogLogsJSON'
)
   )
BEGIN

    DROP SEQUENCE Log.Seq_LogLogsJSON;
END;



IF (EXISTS (SELECT * FROM sys.tables AS T WHERE T.name = 'LogsJSON'))
BEGIN
    DROP TABLE Log.LogsJSON;
END;





CREATE SEQUENCE [Log].[Seq_LogLogsJSON]
AS INT
MINVALUE 1
INCREMENT BY 1
CACHE 30
START WITH 1
NO CYCLE;


CREATE TABLE [Log].[LogsJSON]
(
    [IdLog] [INT] NOT NULL,
    [IdPessoa] [UNIQUEIDENTIFIER] NOT NULL,
    [IdEntidade] [UNIQUEIDENTIFIER] NOT NULL,
    [Entidade] [VARCHAR](128) COLLATE Latin1_General_CI_AI NOT NULL,
    [Acao] [CHAR](1) COLLATE Latin1_General_CI_AI NOT NULL,
    [Data] [DATETIME2](2) NOT NULL,
    [CodSistema] [TINYINT] NOT NULL,
    [IPAdress] VARCHAR(20) NULL,
    Conteudo VARCHAR(MAX),
    CONSTRAINT [FK_LogsJSON_SistemasEspelhamentoLogsCodSistema] FOREIGN KEY ([CodSistema]) REFERENCES Sistema.SistemasEspelhamentoLogs (IdSistema),
    CONSTRAINT CHECK_LogsJSON_Acao CHECK ([LogsJSON].Acao IN ( 'I', 'U', 'D' )),
	INDEX PK_LogsJSON_COLUMNSTORE CLUSTERED COLUMNSTORE
) ON [PRIMARY];

ALTER TABLE Log.LogsJSON
ADD CONSTRAINT DEF_LogsJSON DEFAULT (NEXT VALUE FOR Log.Seq_LogLogsJSON) FOR [IdLog];











/* ==================================================================
--Data: 15/01/2019 
--Autor :Wesley Neves
--Observação: Faz a migração dos dados
			 
-- ==================================================================
*/



WITH Dados AS (
SELECT L.IdLog,
       L.IdPessoa,
       L.IdEntidade,
       L.Entidade,
       L.Acao,
       L.Data,
       L.CodSistema,
       L.IPAdress,
       Conteudo =
       (
           SELECT M2.Campo,M2.ValorAtual
           FROM Log.LogsDetalhes AS M2
           WHERE M2.IdLog = L.IdLog
		   AND LEN(LTRIM(RTRIM(M2.ValorAtual))) > 0
		   ORDER BY M2.Campo
           FOR JSON PATH 
		   --,WITHOUT_ARRAY_WRAPPER
		)
        
FROM Log.Logs AS L
--WHERE L.IdLog = @idLog
),
ReplaceJson AS (
SELECT 
       R.IdLog,
       R.IdPessoa,
       R.IdEntidade,
       R.Entidade,
       R.Acao,
       R.Data,
       R.CodSistema,
       R.IPAdress,
	   R.Conteudo,
	   ReplaceJson1 = REPLACE(REPLACE(R.Conteudo,'"Campo":',''),'"ValorAtual":','')
	   FROM Dados R
),
ReplaceJson2 AS  (
SELECT 
       R.*,
	    ReplaceJson2 = REPLACE(R.ReplaceJson1,',"',':"')
       FROM ReplaceJson R
)
INSERT INTO Log.LogsJSON
(
    
    IdPessoa,
    IdEntidade,
    Entidade,
    Acao,
    Data,
    CodSistema,
    IPAdress,
    Conteudo
)
SELECT R.IdPessoa,
       R.IdEntidade,
       R.Entidade,
       Acao = CASE
                  WHEN (R.Acao = 'Added') THEN
                      'I'
                  WHEN R.Acao = 'Modified' THEN
                      'U'
                  WHEN R.Acao = 'Deleted' THEN
                      'D'
              END,
       R.Data,
       SEL.IdSistema,
       R.IPAdress,
       Conteudo = R.ReplaceJson2
FROM ReplaceJson2 R
    JOIN Sistema.SistemasEspelhamentoLogs AS SEL
        ON R.CodSistema = SEL.Codsistema;



ALTER INDEX ALL ON Log.LogsJSON REBUILD;

SELECT 'ALTER INDEX ALL ON Log.LogsJSON REBUILD;';

EXEC HealthCheck.uspGetSizeOfObjets @objname = N'Log.LogsJSON'; -- nvarchar(776)




ALTER INDEX ALL ON Log.LogsJSON REBUILD WITH (DATA_COMPRESSION = COLUMNSTORE);


SELECT 'ALTER INDEX ALL ON Log.LogsJSON REBUILD WITH (DATA_COMPRESSION = COLUMNSTORE);';
EXEC HealthCheck.uspGetSizeOfObjets @objname = N'Log.LogsJSON'; -- nvarchar(776)





ALTER INDEX ALL ON Log.LogsJSON REBUILD WITH (DATA_COMPRESSION = COLUMNSTORE_ARCHIVE);

GO

SELECT 'ALTER INDEX ALL ON Log.LogsJSON REBUILD WITH (DATA_COMPRESSION = COLUMNSTORE_ARCHIVE);';

EXEC HealthCheck.uspGetSizeOfObjets @objname = N'Log.LogsJSON'; -- nvarchar(776)




/* ==================================================================
--Data: 18/01/2019 
--Autor :Wesley Neves
--Observação: Expurgo
 
-- ==================================================================
*/

IF(EXISTS(SELECT * FROM  sys.tables AS T
WHERE T.name ='LogsExpurgoJSON'))
BEGIN
		
		DROP TABLE Expurgo.LogsExpurgoJSON;
END


IF (EXISTS
(
    SELECT *
    FROM sys.default_constraints AS DC
    WHERE DC.name = 'DEF_LogsExpurgoJSON'
)
   )
BEGIN

    ALTER TABLE Expurgo.LogsExpurgoJSON DROP CONSTRAINT DEF_LogsExpurgoJSON;

END;


IF (EXISTS
(
    SELECT *
    FROM sys.sequences AS S
    WHERE S.name = 'Seq_LogsExpurgoJSON'
)
   )
BEGIN

    DROP SEQUENCE Expurgo.Seq_LogsExpurgoJSON;

END;



CREATE SEQUENCE Expurgo.Seq_LogsExpurgoJSON AS INT START WITH 1 MINVALUE 1 INCREMENT BY 1 CACHE 100 NO CYCLE
 	
	
CREATE TABLE [Expurgo].[LogsExpurgoJSON]
(
    [IdLog] [INT] NOT NULL,
    [IdPessoa] [UNIQUEIDENTIFIER] NOT NULL,
    [IdEntidade] [UNIQUEIDENTIFIER] NOT NULL,
    [Entidade] [VARCHAR](128) COLLATE Latin1_General_CI_AI NOT NULL,
    [Acao] [CHAR](1) COLLATE Latin1_General_CI_AI NOT NULL,
    [Data] [DATETIME2](2) NOT NULL,
    [CodSistema] [TINYINT] NOT NULL,
    [IPAdress] VARCHAR(20) NULL,
    Conteudo VARCHAR(MAX),
    CONSTRAINT [FK_LogsExpurgoJSON_SistemasEspelhamentoLogsCodSistema]
        FOREIGN KEY ([CodSistema])
        REFERENCES Sistema.SistemasEspelhamentoLogs (IdSistema),
    INDEX PK_LogsExpurgo_COLUMNSTORE CLUSTERED COLUMNSTORE
) ON [PRIMARY];

ALTER TABLE [Expurgo].[LogsExpurgoJSON]
ADD CONSTRAINT DEF_LogsExpurgoJSON
    DEFAULT (NEXT VALUE FOR [Expurgo].[Seq_LogsExpurgoJSON]) FOR [IdLog];





WITH DadosExpurgo AS (
SELECT L.IdLog,
       L.IdPessoa,
       L.IdEntidade,
       L.Entidade,
       L.Acao,
       L.Data,
       L.CodSistema,
       L.IPAdress,
       Conteudo =
       (
           SELECT M2.Campo,M2.ValorAtual
           FROM Expurgo.LogsDetalhes AS M2
           WHERE M2.IdLog = L.IdLog
		   AND LEN(LTRIM(RTRIM(M2.ValorAtual))) > 0
		   ORDER BY M2.Campo
           FOR JSON PATH 
		   --,WITHOUT_ARRAY_WRAPPER
		)
        
FROM  Expurgo.Logs AS L

),
ReplaceExpurgoJson AS (
SELECT 
       R.IdLog,
       R.IdPessoa,
       R.IdEntidade,
       R.Entidade,
       R.Acao,
       R.Data,
       R.CodSistema,
       R.IPAdress,
	   R.Conteudo,
	   ReplaceJson1 = REPLACE(REPLACE(R.Conteudo,'"Campo":',''),'"ValorAtual":','')
	   FROM DadosExpurgo R
),
ReplaceExpurgoJson2 AS  (
SELECT 
       R.*,
	    ReplaceJson2 = REPLACE(R.ReplaceJson1,',"',':"')
       FROM ReplaceExpurgoJson R
)
INSERT INTO Expurgo.LogsExpurgoJSON
(
    IdPessoa,
    IdEntidade,
    Entidade,
    Acao,
    Data,
    CodSistema,
    IPAdress,
    Conteudo
)

SELECT R.IdPessoa,
       R.IdEntidade,
       R.Entidade,
       Acao = CASE
                  WHEN (R.Acao = 'Added') THEN
                      'I'
                  WHEN R.Acao = 'Modified' THEN
                      'U'
                  WHEN R.Acao = 'Deleted' THEN
                      'D'
              END,
       R.Data,
       SEL.IdSistema,
       R.IPAdress,
       Conteudo = R.ReplaceJson2
FROM ReplaceExpurgoJson2 R
    JOIN Sistema.SistemasEspelhamentoLogs AS SEL ON R.CodSistema = SEL.Codsistema
--	WHERE R.ReplaceJson2 IS NOT NULL

	
ALTER INDEX ALL ON Expurgo.LogsExpurgoJSON REBUILD;
SELECT 'ALTER INDEX ALL ON Expurgo.LogsExpurgoJSON REBUILD;';
--16210  Paginas
EXEC HealthCheck.uspGetSizeOfObjets @objname = N'Expurgo.LogsExpurgoJSON'; -- nvarchar(776)




ALTER INDEX ALL ON Expurgo.LogsExpurgoJSON REBUILD WITH (DATA_COMPRESSION = COLUMNSTORE);


SELECT 'ALTER INDEX ALL ON Expurgo.LogsExpurgoJSON REBUILD WITH (DATA_COMPRESSION = COLUMNSTORE);';

--16198 Paginas
EXEC HealthCheck.uspGetSizeOfObjets @objname = N'Expurgo.LogsExpurgoJSON'; -- nvarchar(776)





SELECT 'ALTER INDEX ALL ON Expurgo.LogsExpurgoJSON REBUILD WITH (DATA_COMPRESSION = COLUMNSTORE_ARCHIVE);';
ALTER INDEX ALL ON Expurgo.LogsExpurgoJSON REBUILD WITH (DATA_COMPRESSION = COLUMNSTORE_ARCHIVE);

GO

--15950 Paginas
EXEC HealthCheck.uspGetSizeOfObjets @objname = N'Expurgo.LogsExpurgoJSON'; -- nvarchar(776)



EXEC HealthCheck.uspGetSizeOfObjets @objname = N'Expurgo.Logs'; -- nvarchar(776)


EXEC HealthCheck.uspGetSizeOfObjets @objname = N'Expurgo.LogsDetalhes'; -- nvarchar(776)


EXEC HealthCheck.uspGetSizeOfObjets @objname = N'Expurgo.LogsExpurgoJSON'; -- nvarchar(776)




--SELECT COUNT(*) FROM  Log.LogsJSON AS LJ

--SELECT COUNT(*) FROM  Log.Logs AS L

--SELECT COUNT(*) FROM Expurgo.Logs AS L
--SELECT COUNT(*) FROM Expurgo.LogsExpurgoJSON AS LEJ

--SELECT DISTINCT Logs.Acao FROM Expurgo.Logs
--SELECT DISTINCT LEJ.Acao FROM Expurgo.LogsExpurgoJSON AS LEJ




/*



 
ALTER TABLE Expurgo.LogsDetalhes DROP CONSTRAINT FK_LogsDetalhesIdLog_LogsIdLog 
TRUNCATE TABLE Expurgo.LogsDetalhes


ALTER TABLE Expurgo.Logs DROP CONSTRAINT FK_LogsCodSistema_SistemasCodSistema

TRUNCATE TABLE  Expurgo.Logs

ALTER TABLE Log.LogsDetalhes DROP CONSTRAINT [FK_LogsDetalhesIdLog_LogsIdLog]

TRUNCATE TABLE Log.LogsDetalhes

ALTER TABLE Log.Logs DROP CONSTRAINT FK_LogsCodSistema_SistemasCodSistema

TRUNCATE TABLE Log.Logs


*/


SELECT MIN(LJ.Data),MAX(LJ.Data),DATEDIFF(DAY,MIN(LJ.Data),MAX(LJ.Data)) FROM Log.LogsJSON AS LJ


SELECT FORMAT(COUNT(*),'N','Pt-Br') FROM  Log.Logs AS L