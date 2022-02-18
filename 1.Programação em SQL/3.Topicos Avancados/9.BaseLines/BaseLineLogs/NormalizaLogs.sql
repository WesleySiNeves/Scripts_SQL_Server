DROP TABLE IF EXISTS [dbo].[MigracaoJsonLogs];

CREATE TABLE [dbo].[MigracaoJsonLogs]
(
    [id] [INT] NOT NULL IDENTITY(1, 1),
    [IdPessoa] [UNIQUEIDENTIFIER] NULL,
    [IdEntidade] [UNIQUEIDENTIFIER] NULL,
    [Entidade] [VARCHAR](128) COLLATE Latin1_General_CI_AI NULL,
    [Acao] [CHAR](1) COLLATE Latin1_General_CI_AI NULL,
    [Data] [DATETIME2](2) NULL,
    [CodSistema] [SMALLINT] NULL,
    [IPAdress] [VARCHAR](15) COLLATE Latin1_General_CI_AI NULL,
    [Conteudo] [VARCHAR](MAX) COLLATE Latin1_General_CI_AI NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];
GO
ALTER TABLE [dbo].[MigracaoJsonLogs]
ADD CONSTRAINT [CK__MigracaoConteudo] CHECK ((
                                                ISJSON([Conteudo]) = (1)
                                            ));
GO






;WITH Dados
 AS (SELECT L.IdLog,
            L.IdPessoa,
            L.IdEntidade,
            L.Entidade,
            L.Acao,
            L.Data,
            L.CodSistema,
            L.IPAdress,
            Conteudo =
            (
                SELECT M2.Campo,
                       M2.ValorAtual
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
      ReplaceJson
 AS (SELECT R.IdLog,
            R.IdPessoa,
            R.IdEntidade,
            R.Entidade,
            R.Acao,
            R.Data,
            R.CodSistema,
            R.IPAdress,
            R.Conteudo,
            ReplaceJson1 = REPLACE(REPLACE(R.Conteudo, '"Campo":', ''), '"ValorAtual":', '')
     FROM Dados R
    ),
      ReplaceJson2
 AS (SELECT R.*,
            ReplaceJson2 = REPLACE(R.ReplaceJson1, ',"', ':"')
     FROM ReplaceJson R
    )
INSERT INTO dbo.MigracaoJsonLogs
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










