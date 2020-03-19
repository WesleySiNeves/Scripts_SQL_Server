
IF(NOT EXISTS(
SELECT * FROM  sys.tables AS T
WHERE T.name  ='LogsJson'))
BEGIN
		



IF(EXISTS (
              SELECT *
                FROM sys.default_constraints AS DC
               WHERE
                  DC.name = 'DEF_SeqLogLogsJson'
          )
  )
    BEGIN
        ALTER TABLE Log.LogsJson DROP CONSTRAINT DEF_SeqLogLogsJson;
    END;


IF(EXISTS (
              SELECT *
                FROM sys.default_constraints AS DC
               WHERE
                  DC.name = 'DEF_ExpurgoLogLogsJson'
          )
  )
    BEGIN
        ALTER TABLE Expurgo.LogsJson DROP CONSTRAINT DEF_ExpurgoLogLogsJson;
    END;

IF(EXISTS (
              SELECT *
                FROM sys.default_constraints AS DC
               WHERE
                  DC.name = 'DEF_SistemaSistemasEspelhamentos'
          )
  )
    BEGIN
        ALTER TABLE Sistema.SistemasEspelhamentos
        DROP CONSTRAINT DEF_SistemaSistemasEspelhamentos;
    END;


IF(EXISTS (
              SELECT * FROM sys.sequences AS S WHERE S.name = 'Seq_LogLogsJson'
          )
  )
    BEGIN
        DROP SEQUENCE Log.Seq_LogLogsJson;
    END;


IF(EXISTS (
              SELECT *
                FROM sys.sequences AS S
               WHERE
                  S.name = 'Seq_SistemasEspelhamentos'
          )
  )
    BEGIN
        ALTER TABLE Sistema.SistemasEspelhamentos
        DROP CONSTRAINT DEF_SistemasEspelhamentos

        DROP SEQUENCE Sistema.Seq_SistemasEspelhamentos;
    END;


IF(EXISTS (
              SELECT * FROM sys.sequences AS S WHERE S.name = 'Seq_ExpurgoLogsJson'
          )
  )
    BEGIN
        DROP SEQUENCE Expurgo.Seq_ExpurgoLogsJson;
    END;


IF(EXISTS (
              SELECT * FROM sys.tables AS T WHERE T.name = 'SistemasEspelhamentos'
          )
  )
    BEGIN
        IF(EXISTS (
                      SELECT *
                        FROM sys.foreign_keys AS FK
                       WHERE
                          FK.name = 'FK_LogsSistemasEspelhamentosCodsistema'
                  )
          )
            BEGIN
                ALTER TABLE Sistema.LogsSistemasEspelhamentos
                DROP CONSTRAINT FK_LogsSistemasEspelhamentosCodsistema;
            END;

        IF(EXISTS (
                      SELECT * FROM sys.triggers AS T WHERE T.name = 'Trg_SistemaSistemas'
                  )
          )
            BEGIN
                DROP TRIGGER Sistema.Trg_SistemaSistemas;
            END;

        IF(EXISTS (
                      SELECT *
                        FROM sys.foreign_keys AS FK
                       WHERE
                          FK.name = 'FK_ExpurgoLogsJson_SistemasEspelhamentosCodSistema'
                  )
          )
            BEGIN
                ALTER TABLE Expurgo.LogsJson
                DROP CONSTRAINT FK_ExpurgoLogsJson_SistemasEspelhamentosCodSistema;
            END;
    END;


IF(EXISTS (
              SELECT * FROM sys.tables AS T WHERE T.name = 'SistemasEspelhamentos'
          )
  )
    BEGIN
        ALTER TABLE Log.LogsJson
        DROP CONSTRAINT FK_LogsJson_SistemasEspelhamentosIdSistemaEspelhamento

        ALTER TABLE Sistema.SistemasEspelhamentos
        DROP CONSTRAINT FK_SistemasEspelhamentosCodsistema

        ALTER TABLE Expurgo.LogsJson
        DROP CONSTRAINT FK_ExpurgoLogsJson_SistemasEspelhamentosIdSistemaEspelhamento

        DROP TABLE Sistema.SistemasEspelhamentos
    END

IF(NOT EXISTS (
                  SELECT * FROM sys.tables AS T WHERE T.name = 'SistemasEspelhamentos'
              )
  )
    BEGIN
        CREATE SEQUENCE Sistema.Seq_SistemasEspelhamentos
        AS TINYINT
        START WITH 0
        INCREMENT BY 1
        MINVALUE 0
        NO CYCLE
        NO CACHE;

        CREATE TABLE Sistema.SistemasEspelhamentos
        (
            IdSistemaEspelhamento TINYINT          NOT NULL CONSTRAINT DEF_SistemasEspelhamentos DEFAULT(NEXT VALUE FOR Sistema.Seq_SistemasEspelhamentos),
            CodSistema            UNIQUEIDENTIFIER NOT NULL,
            Nome                  VARCHAR(100),
            Descricao             VARCHAR(200)     CONSTRAINT PK_SistemasEspelhamentos PRIMARY KEY(IdSistemaEspelhamento),
            CONSTRAINT Unique_SistemasEspelhamentosCodsistema UNIQUE(CodSistema),
            CONSTRAINT FK_SistemasEspelhamentosCodsistema FOREIGN KEY(CodSistema)REFERENCES Sistema.Sistemas(CodSistema)
        );

        INSERT INTO Sistema.SistemasEspelhamentos(
                                                     CodSistema,
                                                     Nome,
                                                     Descricao
                                                 )
        SELECT S.CodSistema, S.Nome, S.Descricao FROM Sistema.Sistemas AS S;
    END;


/* ==================================================================
--Data: 17/01/2019 
--Autor :Wesley Neves
--Observação:  Criação da tabela Logs Em Json
 
-- ==================================================================
*/


IF(EXISTS (
              SELECT *
                FROM sys.default_constraints AS DC
               WHERE
                  DC.name = 'DEF_ExpurgoLogsJson'
          )
  )
    BEGIN
        ALTER TABLE Expurgo.LogsJson DROP CONSTRAINT DEF_ExpurgoLogsJson;
    END;


IF(EXISTS (
              SELECT S.name,
                     T.name
                FROM sys.tables AS T
                     JOIN sys.schemas AS S ON T.schema_id = S.schema_id
               WHERE
                  T.name = 'LogsJson'
                  AND S.name = 'Log'
          )
  )
    BEGIN
        DROP TABLE Log.LogsJson;
    END;

IF(EXISTS (
              SELECT S.name,
                     T.name
                FROM sys.tables AS T
                     JOIN sys.schemas AS S ON T.schema_id = S.schema_id
               WHERE
                  T.name = 'LogsJson'
                  AND S.name = 'Expurgo'
          )
  )
    BEGIN
        DROP TABLE Expurgo.LogsJson;
    END;

CREATE SEQUENCE [Log].[Seq_LogLogsJson]
AS INT
MINVALUE 1
INCREMENT BY 1
CACHE 100
START WITH 1
NO CYCLE;




CREATE TABLE [Log].[LogsJson]
(
    [IdLog] [INT] NOT NULL CONSTRAINT DEF_SeqLogLogsJson DEFAULT (NEXT VALUE FOR Log.Seq_LogLogsJson),
    [IdPessoa] [UNIQUEIDENTIFIER] NOT NULL,
    [IdEntidade] [UNIQUEIDENTIFIER] NOT NULL,
    [Entidade] [VARCHAR](128) COLLATE Latin1_General_CI_AI NOT NULL,
    IdLogAntigo UNIQUEIDENTIFIER NULL,
    [Acao] [CHAR](1) COLLATE Latin1_General_CI_AI NOT NULL,
    [Data] [DATETIME2](2) NOT NULL,
    [IdSistemaEspelhamento] [TINYINT] NOT NULL,
    [IPAdress] VARCHAR(30) NULL,
    Conteudo VARCHAR(MAX),
    CONSTRAINT [FK_LogsJson_SistemasEspelhamentosIdSistemaEspelhamento] FOREIGN KEY (IdSistemaEspelhamento) REFERENCES Sistema.SistemasEspelhamentos (IdSistemaEspelhamento),
    CONSTRAINT CHECK_LogsJson_Acao CHECK ([LogsJson].Acao IN ( 'I', 'U', 'D' )),
    INDEX PK_LogsJson CLUSTERED COLUMNSTORE WITH(DATA_COMPRESSION=COLUMNSTORE_ARCHIVE)
) ON [PRIMARY];


CREATE UNIQUE NONCLUSTERED INDEX IX_LogLogsJson_IdLogAntigo
ON Log.LogsJson (IdLogAntigo)
WHERE IdLogAntigo IS NOT NULL;

CREATE SEQUENCE [Expurgo].[Seq_ExpurgoLogsJson]
AS INT
MINVALUE 1
INCREMENT BY 1
CACHE 100
START WITH 1
NO CYCLE;

CREATE TABLE [Expurgo].[LogsJson]
(
    [IdLog] [INT] NOT NULL CONSTRAINT DEF_ExpurgoLogLogsJson DEFAULT (NEXT VALUE FOR Expurgo.Seq_ExpurgoLogsJson) ,
    [IdPessoa] [UNIQUEIDENTIFIER] NOT NULL,
    [IdEntidade] [UNIQUEIDENTIFIER] NOT NULL,
    [Entidade] [VARCHAR](128) COLLATE Latin1_General_CI_AI NOT NULL,
    IdLogAntigo UNIQUEIDENTIFIER NULL,
    [Acao] [CHAR](1) COLLATE Latin1_General_CI_AI NOT NULL,
    [Data] [DATETIME2](2) NOT NULL,
    [IdSistemaEspelhamento] [TINYINT] NOT NULL,
    [IPAdress] VARCHAR(30) NULL,
    Conteudo VARCHAR(MAX),
    CONSTRAINT [FK_ExpurgoLogsJson_SistemasEspelhamentosIdSistemaEspelhamento] FOREIGN KEY (IdSistemaEspelhamento) REFERENCES Sistema.SistemasEspelhamentos (IdSistemaEspelhamento),
    CONSTRAINT CHECK_ExpurgoLogsJson_Acao CHECK (LogsJson.Acao IN ( 'I', 'U', 'D' )),
    INDEX PK_ExpurgoLogsJson CLUSTERED COLUMNSTORE WITH(DATA_COMPRESSION=COLUMNSTORE_ARCHIVE)
) ON [PRIMARY];

CREATE UNIQUE NONCLUSTERED INDEX IX_ExpurgoLogsJson_IdLogAntigo
ON Expurgo.LogsJson (IdLogAntigo)
WHERE IdLogAntigo IS NOT NULL;


END

GO

CREATE OR ALTER TRIGGER Sistema.Trg_SistemaSistemas
ON Sistema.Sistemas
AFTER INSERT, UPDATE
AS
BEGIN


    --1 New  ,2-Update (As ações de deletes não serão espelhadas para a tebela "Sistema.SistemasEspelhamento")
    DECLARE @Id_Tipo_Operacao TINYINT,
            @CountInserted INT,
            @CountDeleted INT;

    SELECT @CountInserted = ISNULL(COUNT(*), 0)
    FROM INSERTED;
    SELECT @CountDeleted = ISNULL(COUNT(*), 0)
    FROM DELETED;

    IF ((ISNULL(@CountInserted, 0) = 0) AND (ISNULL(@CountDeleted, 0) = 0))
        RETURN;

    -- Tipo Operação 
    -- 1 - Inclusão 
    -- 2 - Alteração 
    -- 3 - Exclusão 

    SET @Id_Tipo_Operacao = CASE
                                WHEN @CountInserted > 0
                                     AND @CountDeleted > 0 THEN
                                    2 -- Alteração 
                                WHEN @CountInserted > 0
                                     AND @CountDeleted = 0 THEN
                                    1 -- Inclusão 
                                WHEN @CountInserted = 0
                                     AND @CountDeleted > 0 THEN
                                    3
                            END; -- Exclusão  



    IF (@Id_Tipo_Operacao = 1)
    BEGIN

	
        INSERT INTO Sistema.SistemasEspelhamentos
        (
            IdSistemaEspelhamento,
            Codsistema,
            Nome,
            Descricao
        )
        SELECT NEXT VALUE FOR Sistema.Seq_SistemasEspelhamentos,
               Inserted.CodSistema,
               Inserted.Nome,
               Inserted.Descricao
        FROM Inserted;

    END;

    IF (@Id_Tipo_Operacao = 2)
    BEGIN

        UPDATE Espelho
        SET Espelho.Nome = I.Nome,
            Espelho.Descricao = I.Descricao
        FROM Sistema.SistemasEspelhamentos Espelho
            JOIN Inserted I ON Espelho.CodSistema = I.CodSistema;
    END;

END;








