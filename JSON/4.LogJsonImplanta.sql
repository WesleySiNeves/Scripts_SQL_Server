SELECT T.object_id,
       S.name,
       T.name
FROM sys.schemas AS S
    JOIN sys.tables AS T
        ON S.schema_id = T.schema_id;


IF (NOT EXISTS
(
    SELECT *
    FROM sys.tables AS T
    WHERE T.name = 'SistemasEspelhamentoLogs'
)
   )
BEGIN

    CREATE TABLE Sistema.SistemasEspelhamentoLogs
    (
        IdSistema TINYINT IDENTITY(0, 1) PRIMARY KEY,
        Codsistema UNIQUEIDENTIFIER NOT NULL
            UNIQUE
            FOREIGN KEY (Codsistema) REFERENCES Sistema.Sistemas (CodSistema),
        NomeSistema VARCHAR(100),
        Descricao VARCHAR(200)
    );


	INSERT INTO Sistema.SistemasEspelhamentoLogs
SELECT S.CodSistema,
       S.Nome,
       S.Descricao
FROM Sistema.Sistemas AS S;


END;

	IF (NOT EXISTS (SELECT * FROM sys.tables AS T WHERE T.name = 'LogsJSON'))
	BEGIN

		CREATE SEQUENCE Seq_LogLogsJSON
		AS INT
		MINVALUE 1
		INCREMENT BY 1
		CACHE 100
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
			[IPAdress] [VARCHAR](12) COLLATE Latin1_General_CI_AI NULL,
			[Conteudo] [VARCHAR](8000) COLLATE Latin1_General_CI_AI NULL
		) ON [PRIMARY];

		ALTER TABLE Log.LogsJSON
		ADD CONSTRAINT [CKLogsJSONConteudo] CHECK ((
													  ISJSON(LogsJSON.Conteudo) = (1)
												  ));

		ALTER TABLE Log.LogsJSON
		ADD CONSTRAINT CKLogsJSONAcao CHECK (LogsJSON.Acao IN ( 'I', 'U', 'D' ));

		ALTER TABLE Log.LogsJSON
		ADD CONSTRAINT [PK_LogsJSON]
			PRIMARY KEY CLUSTERED ([IdLog])
			WITH (FILLFACTOR = 100);


		ALTER TABLE Log.LogsJSON
		ADD CONSTRAINT [FK_LogsCodSistema_SistemasEspelhamentoLogsCodSistema]
			FOREIGN KEY ([CodSistema])
			REFERENCES Sistema.SistemasEspelhamentoLogs ([Codsistema]);

		ALTER TABLE Log.LogsJSON
		ADD CONSTRAINT DEF_LogsJSON
			DEFAULT (NEXT VALUE FOR dbo.Seq_LogLogsJSON) FOR IdLog;
	END;







IF (OBJECT_ID('TEMPDB..#Logs') IS NOT NULL)
    DROP TABLE #Logs;

CREATE TABLE #Logs
(
    [Entidade] VARCHAR(250),
    TotalLogs INT
);



INSERT INTO #Logs
(
    Entidade,
    TotalLogs
)

SELECT L.Entidade,COUNT(*) AS TotalLogs FROM Log.Logs AS L
GROUP BY L.Entidade
ORDER BY COUNT(*) DESC


--DELETE FROM Log.Logs
--WHERE Logs.Acao ='Deleted'

IF ( OBJECT_ID('TEMPDB..#TabelasLogs') IS NOT NULL )
    DROP TABLE #TabelasLogs;	


CREATE TABLE #TabelasLogs
(
    [Entidade] VARCHAR(250),
    [IdEntidade] NVARCHAR(128)
);


INSERT INTO #TabelasLogs
(
    Entidade,
    IdEntidade
)

SELECT TL.Entidade,
	   C.name AS IdEntidade
FROM sys.tables AS T
    JOIN sys.indexes AS I
        ON T.object_id = I.object_id
           AND I.type = 1
    JOIN sys.index_columns AS IC ON I.object_id = IC.object_id AND I.index_id = IC.index_id
	JOIN sys.columns AS C ON I.object_id = C.object_id AND IC.column_id = C.column_id
	JOIN #Logs AS TL ON T.object_id = OBJECT_ID(TL.Entidade)
WHERE T.object_id IN (
                         SELECT OBJECT_ID(TL.Entidade) FROM #Logs AS TL
                     )
      AND IC.key_ordinal = 1





/* declare variables */
DECLARE @Entidade VARCHAR(250),@IdEntidade VARCHAR(150)

DECLARE cursor_AjustaLogs CURSOR FAST_FORWARD READ_ONLY FOR SELECT TL.Entidade,TL.IdEntidade
                                                                   FROM #TabelasLogs AS TL

OPEN cursor_AjustaLogs

FETCH NEXT FROM cursor_AjustaLogs INTO @Entidade,@IdEntidade

WHILE @@FETCH_STATUS = 0
BEGIN
    

	DECLARE @Script VARCHAR(800) = CONCAT('DELETE FROM Log.LogsDetalhes WHERE LogsDetalhes.IdLog IN (','SELECT L.IdLog FROM Log.Logs AS L WHERE L.Entidade = ',
	CHAR(39),@Entidade,CHAR(39),' AND L.IdEntidade NOT IN ( SELECT L2.',@IdEntidade,' FROM ',@Entidade,' AS L2 ))')

	PRINT @Script;
                              
   EXEC (@Script)

  DECLARE @ScriptDetalhe  VARCHAR(800) = CONCAT('DELETE L FROM Log.Logs L  WHERE L.IdLog', ' NOT IN ( SELECT LD.IdLog FROM Log.LogsDetalhes AS LD )')

   PRINT @ScriptDetalhe

   EXEC (@ScriptDetalhe)


 


    FETCH NEXT FROM cursor_AjustaLogs INTO @Entidade,@IdEntidade
END

CLOSE cursor_AjustaLogs
DEALLOCATE cursor_AjustaLogs


SELECT * FROM  Log.Logs AS L

/* declare variables */
DECLARE @chaveMov UNIQUEIDENTIFIER,
        @dataNov DATETIME,
        @JSON VARCHAR(4000);

DECLARE cursor_InserirMovimentos CURSOR FAST_FORWARD READ_ONLY FOR
SELECT chave = M.IdMovimento,
       JSONV =
       (
           SELECT *
           FROM  Contabilidade.Movimentos AS M2
           WHERE M2.IdMovimento = M.IdMovimento
           FOR JSON PATH, INCLUDE_NULL_VALUES
       )
FROM Contabilidade.Movimentos AS M
WHERE M.IdMovimento IN 
(
SELECT L.IdEntidade FROM Log.Logs AS L
WHERE L.Entidade ='Contabilidade.Movimentos'
)


OPEN cursor_InserirPagamentos;

FETCH NEXT FROM cursor_InserirPagamentos
INTO @chave,
     @data,
     @JSON;

WHILE @@FETCH_STATUS = 0
BEGIN
    --SELECT @chave,@JSON;
    INSERT INTO Log.LogsJSON
    (
        IdLog,
        IdPessoa,
        IdEntidade,
        ObjectId,
        Acao,
        Data,
        IdSistema,
        IPAdress,
        Valor
    )
    VALUES
    (   DEFAULT,                         -- idlog - uniqueidentifier,
        '00000000-0000-0000-0000-000000000001',
        @chave,                          -- IdEntidade - uniqueidentifier
        OBJECT_ID('Despesa.Pagamentos'), -- Entidade - varchar(200)
        'I',                             -- Acao - char(1)
        @data,
        2,                               --siscont,
        DEFAULT,
        @JSON                            -- Valor - varchar(4000)
    );


    FETCH NEXT FROM cursor_InserirPagamentos
    INTO @chave,
         @data,
         @JSON;
END;

CLOSE cursor_InserirPagamentos;
DEALLOCATE cursor_InserirPagamentos;





/* ==================================================================
--Data: 13/08/2018 
--Autor :Wesley Neves
--Observação: Inserir Pagamentos
 
-- ==================================================================
*/


/* declare variables */
DECLARE @chave UNIQUEIDENTIFIER,
        @data DATETIME,
        @JSON VARCHAR(4000);

DECLARE cursor_InserirPagamentos CURSOR FAST_FORWARD READ_ONLY FOR
SELECT chave = P.IdPagamento,
       Data = P.DataPagamento,
       JSONV =
       (
           SELECT *
           FROM Despesa.Pagamentos AS P2
           WHERE P2.IdPagamento = P.IdPagamento
           FOR JSON PATH, INCLUDE_NULL_VALUES
       )
FROM Despesa.Pagamentos AS P;


OPEN cursor_InserirPagamentos;

FETCH NEXT FROM cursor_InserirPagamentos
INTO @chave,
     @data,
     @JSON;

WHILE @@FETCH_STATUS = 0
BEGIN
    --SELECT @chave,@JSON;
    INSERT INTO Log.LogsJSON
    (
        IdLog,
        IdPessoa,
        IdEntidade,
        ObjectId,
        Acao,
        Data,
        IdSistema,
        IPAdress,
        Valor
    )
    VALUES
    (   DEFAULT,                         -- idlog - uniqueidentifier,
        '00000000-0000-0000-0000-000000000001',
        @chave,                          -- IdEntidade - uniqueidentifier
        OBJECT_ID('Despesa.Pagamentos'), -- Entidade - varchar(200)
        'I',                             -- Acao - char(1)
        @data,
        2,                               --siscont,
        DEFAULT,
        @JSON                            -- Valor - varchar(4000)
    );


    FETCH NEXT FROM cursor_InserirPagamentos
    INTO @chave,
         @data,
         @JSON;
END;

CLOSE cursor_InserirPagamentos;
DEALLOCATE cursor_InserirPagamentos;




/* ==================================================================
--Data: 15/08/2018 
--Autor :Wesley Neves
--Observação: Inserir Empenhos
 
-- ==================================================================
*/
GO

/* declare variables */
DECLARE @chave UNIQUEIDENTIFIER,
        @data DATETIME,
        @JSON VARCHAR(4000);

DECLARE cursor_InserirEmpenhos CURSOR FAST_FORWARD READ_ONLY FOR
SELECT chave = E.IdEmpenho,
       data = E.Data,
       JSONV =
       (
           SELECT *
           FROM Despesa.Empenhos AS E2
           WHERE E2.IdEmpenho = E.IdEmpenho
           FOR JSON PATH, INCLUDE_NULL_VALUES
       )
FROM Despesa.Empenhos AS E;


OPEN cursor_InserirEmpenhos;

FETCH NEXT FROM cursor_InserirEmpenhos
INTO @chave,
     @data,
     @JSON;

WHILE @@FETCH_STATUS = 0
BEGIN
    --SELECT @chave,@JSON;

    INSERT INTO Log.LogsJSON
    (
        IdLog,
        IdPessoa,
        IdEntidade,
        ObjectId,
        Acao,
        Data,
        IdSistema,
        IPAdress,
        Valor
    )
    VALUES
    (   DEFAULT,                       -- idlog - uniqueidentifier
        '00000000-0000-0000-0000-000000000001',
        @chave,                        -- IdEntidade - uniqueidentifier
        OBJECT_ID('Despesa.Empenhos'), -- Entidade - varchar(200)
        'I',                           -- Acao - char(1)
        @data,
        2,
        DEFAULT,
        @JSON                          -- Valor - varchar(4000)
    );


    FETCH NEXT FROM cursor_InserirEmpenhos
    INTO @chave,
         @data,
         @JSON;
END;

CLOSE cursor_InserirEmpenhos;
DEALLOCATE cursor_InserirEmpenhos;




/* ==================================================================
--Data: 15/08/2018 
--Autor :Wesley Neves
--Observação: Inserir Liquidacoes
 
-- ==================================================================
*/
GO

/* declare variables */
DECLARE @chave UNIQUEIDENTIFIER,
        @data DATETIME,
        @JSON VARCHAR(4000);

DECLARE cursor_InserirLiquidacoes CURSOR FAST_FORWARD READ_ONLY FOR
SELECT chave = E.IdLiquidacao,
       data = E.DataLiquidacao,
       JSONV =
       (
           SELECT *
           FROM Despesa.Liquidacoes AS L2
           WHERE L2.IdLiquidacao = E.IdLiquidacao
           FOR JSON PATH, INCLUDE_NULL_VALUES
       )
FROM Despesa.Liquidacoes AS E;


OPEN cursor_InserirLiquidacoes;

FETCH NEXT FROM cursor_InserirLiquidacoes
INTO @chave,
     @data,
     @JSON;

WHILE @@FETCH_STATUS = 0
BEGIN
    --SELECT @chave,@JSON;


    INSERT INTO Log.LogsJSON
    (
        IdLog,
        IdPessoa,
        IdEntidade,
        ObjectId,
        Acao,
        Data,
        IdSistema,
        IPAdress,
        Valor
    )
    VALUES
    (   DEFAULT,                          -- idlog - uniqueidentifier
        '00000000-0000-0000-0000-000000000001',
        @chave,                           -- IdEntidade - uniqueidentifier
        OBJECT_ID('Despesa.Liquidacoes'), -- Entidade - varchar(200)
        'I',                              -- Acao - char(1)
        @data,
        2,
        DEFAULT,
        @JSON                             -- Valor - varchar(4000)
    );


    FETCH NEXT FROM cursor_InserirLiquidacoes
    INTO @chave,
         @data,
         @JSON;

END;

CLOSE cursor_InserirLiquidacoes;
DEALLOCATE cursor_InserirLiquidacoes;





/* ==================================================================
--Data: 15/08/2018 
--Autor :Wesley Neves
--Observação: Inserir Receitas
 
-- ==================================================================
*/
GO

/* declare variables */
DECLARE @chave UNIQUEIDENTIFIER,
        @data DATETIME,
        @JSON VARCHAR(4000);

DECLARE cursor_InserirRecebimentos CURSOR FAST_FORWARD READ_ONLY FOR
SELECT chave = E.IdRecebimento,
       Data = E.DataRecebimento,
       JSONV =
       (
           SELECT *
           FROM Receita.Recebimentos AS R2
           WHERE R2.IdRecebimento = E.IdRecebimento
           FOR JSON PATH, INCLUDE_NULL_VALUES
       )
FROM Receita.Recebimentos AS E;


OPEN cursor_InserirRecebimentos;

FETCH NEXT FROM cursor_InserirRecebimentos
INTO @chave,
     @data,
     @JSON;

WHILE @@FETCH_STATUS = 0
BEGIN


    INSERT INTO Log.LogsJSON
    (
        IdLog,
        IdPessoa,
        IdEntidade,
        ObjectId,
        Acao,
        Data,
        IdSistema,
        IPAdress,
        Valor
    )
    VALUES
    (   DEFAULT,                           -- idlog - uniqueidentifier
        '00000000-0000-0000-0000-000000000001',
        @chave,                            -- IdEntidade - uniqueidentifier
        OBJECT_ID('Receita.Recebimentos'), -- Entidade - varchar(200)
        'I',                               -- Acao - char(1)
        @data,
        2,
        DEFAULT,
        @JSON                              -- Valor - varchar(4000)
    );


    FETCH NEXT FROM cursor_InserirRecebimentos
    INTO @chave,
         @data,
         @JSON;
END;

CLOSE cursor_InserirRecebimentos;
DEALLOCATE cursor_InserirRecebimentos;

GO


SELECT FORMAT(449760, 'N', 'Pt-Br'); --449.760,00

SELECT *
FROM Log.Logs AS L;
SELECT *
FROM Log.LogsJSON AS LJ;

--ALTER DATABASE Implanta SET COMPATIBILITY_LEVEL =130

DECLARE @IdEntidade UNIQUEIDENTIFIER = NULL; --'BE07940F-8819-4AF6-8812-086CDC4697BA';
DECLARE @Entidade VARCHAR(200) = NULL, -- 'Receita.Recebimentos',
        @Acao CHAR(1) = NULL;          -- 'N';



SELECT TOP 100
    LJ.idlog,
    Entidade = OBJECT_ID(LJ.ObjectId),
    LJ.IdEntidade,
    LJ.Acao,
    LJ.Data,
    LJ.IPAdress,
    --LJ.Valor ,
    Campo = X.[Key],
    Valor = X.Value
-- X.Type
FROM Log.LogsJSON AS LJ
    CROSS APPLY
(
    SELECT *
    FROM OPENJSON(
         (
             SELECT OJ.Value FROM OPENJSON(LJ.Valor) AS OJ
         )
                 ) B
) X
WHERE (
          @IdEntidade IS NULL
          OR (
                 @IdEntidade IS NOT NULL
                 AND LJ.IdEntidade = @IdEntidade
             )
             AND (
                     @Acao IS NULL
                     OR (
                            @Acao IS NOT NULL
                            AND LJ.Acao = @Acao
                        )
                 )
             AND (
                     @Entidade IS NOT NULL
                     OR (
                            @Entidade IS NOT NULL
                            AND LJ.ObjectId = OBJECT_ID(@Entidade)
                        )
                 )
      );
	  


