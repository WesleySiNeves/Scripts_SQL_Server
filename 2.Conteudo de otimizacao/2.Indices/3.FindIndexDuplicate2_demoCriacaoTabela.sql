DECLARE @tabela VARCHAR(300) = 'Pessoas';
DECLARE @NomeIndice VARCHAR(300) = NULL; --'IX_Pessoas_NomeRazaoSocialEstrangeiroAtivoCPFCNPJ';

IF (OBJECT_ID('TEMPDB..#DadosTabela') IS NOT NULL)
    DROP TABLE #DadosTabela;


IF (OBJECT_ID('TEMPDB..#DadosIndices') IS NOT NULL)
    DROP TABLE #DadosIndices;

CREATE TABLE #DadosIndices (
    [object_id] INT,
    [index_id] INT,
    [Id] INT,
    [name] NVARCHAR(128),
    [type] TINYINT,
    [type_desc] NVARCHAR(60),
    [is_unique] BIT,
    [is_primary_key] BIT,
    [is_unique_constraint] BIT,
    [index_column_id] INT,
    [column_id] INT,
    [key_ordinal] TINYINT,
    [is_included_column] BIT,
    [Nome Coluna] NVARCHAR(128),
    [Posicao Coluna] INT);

CREATE TABLE #DadosTabela (
    [Schema] VARCHAR(200),
    Tabela VARCHAR(200),
    object_id BIGINT,
    name VARCHAR(300),
    column_id INT,
    Type VARCHAR(200),
    max_length INT,
    collation_name VARCHAR(200),
    is_nullable BIT,
    is_rowguidcol BIT,
    IsDeterministic BIT);

WITH DadoTabelaCampos
  AS (SELECT [Schema] = SCHEMA_NAME(T.schema_id),
             [Tabela] = T.name,
             C.object_id,
             C.name,
             C.column_id,
             [Type] = T2.name,
             C.max_length,
             C.collation_name,
             C.is_nullable,
             C.is_rowguidcol,
             CAST(ISNULL(COLUMNPROPERTY(C.object_id, C.name, N'IsDeterministic'), 0) AS BIT) AS [IsDeterministic]
        FROM sys.tables AS T
        JOIN sys.columns AS C
        JOIN sys.types AS T2
          ON C.system_type_id = T2.system_type_id
          ON T.object_id = C.object_id
       WHERE (   @tabela IS NULL
            OR   T.name = @tabela))
INSERT INTO #DadosTabela
SELECT *
  FROM DadoTabelaCampos R;
WITH Indices
  AS (SELECT I.object_id,
             I.index_id,
             [Id] = (CASE IC.key_ordinal
                          WHEN 0 THEN IC.index_column_id
                          ELSE IC.key_ordinal END),
             I.name,
             I.type,
             I.type_desc,
             I.is_unique,
             I.is_primary_key,
             I.is_unique_constraint,
             IC.index_column_id,
             IC.column_id,
             IC.key_ordinal,
             IC.is_included_column,
             [Nome Coluna] = clmns.name,
             [Posicao Coluna] = clmns.column_id
        FROM sys.tables AS tbl
       INNER JOIN sys.indexes I
          ON (I.object_id    = tbl.object_id)
         AND (I.index_id     > 0)
        JOIN sys.index_columns AS IC
          ON I.object_id     = IC.object_id
         AND I.index_id      = IC.index_id
        JOIN sys.columns AS clmns
          ON clmns.object_id = IC.object_id
         AND clmns.column_id = IC.column_id)
INSERT INTO #DadosIndices
SELECT *
  FROM Indices;

;WITH PrimeiroResultSet
   AS (SELECT T1.object_id,
              T1.[Schema],
              T1.Tabela,
              [Coluna] = T1.name,
              [Key index] = IIF(Ix.key_ordinal = 1, 'SIM', 'Não'),
              [Coluna indexada] = IIF(T1.column_id = Ix.column_id, 'Sim', 'Não'),
              --  T1.column_id,
              T1.type,
              T1.max_length,
              T1.IsDeterministic,
              Ix.name,
              Ix.index_id,
              Ix.type_desc,
              [duplicado] = DENSE_RANK() OVER (PARTITION BY T1.object_id ORDER BY T1.name),
              [Colunas Indices] = CASE
                                       WHEN EXISTS (   SELECT 1
                                                         FROM #DadosIndices AS DI
                                                        WHERE DI.object_id          = Ix.object_id
                                                          AND DI.is_included_column = 1) THEN '0'
                                       ELSE (   SELECT STRING_AGG(D.[Nome Coluna], ',')
                                                  FROM #DadosIndices AS D
                                                 WHERE D.object_id   = Ix.object_id
                                                   AND D.index_id    = Ix.index_id
                                                   AND D.key_ordinal > 1) END,
              Ix.is_unique,
              Ix.is_unique_constraint,
              Ix.index_column_id,
              Ix.column_id,
              --Ix.key_ordinal,
              --Ix.is_included_column
              [Coluna Indice] = Ix.[Nome Coluna]
         FROM #DadosTabela T1
         LEFT JOIN #DadosIndices Ix
           ON T1.OBJECT_ID = Ix.OBJECT_ID
          AND T1.column_id = Ix.column_id
        WHERE (   @NomeIndice IS NULL
             OR   Ix.[Nome Coluna] = @NomeIndice)
          AND Ix.index_column_id   = 1),
      SegundoResultSet
   AS (SELECT [Indice] = Ix.name,
              Ix.[Nome Coluna],
              Ix.object_id,
              Ix.name,
              Ix.index_column_id,
              Ix.column_id,
              Ix.key_ordinal,
              Ix.is_included_column,
              Ix.[Posicao Coluna],
              
              [Colunas Indices] = CASE
                                       WHEN EXISTS (   SELECT 1
                                                         FROM #DadosIndices AS DI
                                                        WHERE DI.object_id          = Ix.object_id
                                                          AND DI.is_included_column = 1) THEN '0'
                                       ELSE (   SELECT STRING_AGG(D.[Nome Coluna], ',')
                                                  FROM #DadosIndices AS D
                                                 WHERE D.object_id   = Ix.object_id
                                                   AND D.index_id    = Ix.index_id
                                                   AND D.key_ordinal > 1) END

         --[Colunas Incluidas] = (   SELECT STRING_AGG(D3.[Nome Coluna], ',')
         --                            FROM #DadosIndices AS D3
         --                           WHERE D3.object_id   = Ix.object_id
         --                             AND D3.key_ordinal > 1
         --                             AND D3.[Nome Coluna] IN (   SELECT D2.[Nome Coluna]
         --                                                           FROM #DadosIndices AS D2
         --                                                          WHERE D2.object_id = Ix.object_id
         --                                                            AND D2.index_id  = Ix.index_id ))
         FROM #DadosIndices AS Ix
        WHERE Ix.OBJECT_ID   = '270624007'
          AND Ix.key_ordinal = 1)
SELECT *,
       [Colunas Excluidas] = (   SELECT STRING_AGG(D.[Nome Coluna], ',')
                                   FROM #DadosIndices AS D
                                  WHERE D.object_id   = '270624007'
                                    AND D.key_ordinal > 1
                                    AND D.[Nome Coluna] NOT IN (   SELECT D2.[Nome Coluna]
                                                                     FROM #DadosIndices AS D2
                                                                    WHERE D2.object_id     = '270624007'
                                                                      AND D2.index_id      <> D.index_id
                                                                      AND D2.[Nome Coluna] = D.[Nome Coluna] ))
  FROM SegundoResultSet;





/*
 16	1	IX_Pessoas_NomeRazaoSocialEstrangeiroAtivo	2	NONCLUSTERED	0	0	0	1	2	1	0	NomeRazaoSocial	2
16	2	IX_Pessoas_NomeRazaoSocialEstrangeiroAtivo	2	NONCLUSTERED	0	0	0	2	15	2	0	Estrangeiro	15
16	3	IX_Pessoas_NomeRazaoSocialEstrangeiroAtivo	2	NONCLUSTERED	0	0	0	3	16	3	0	Ativo	16
 */





--1)[IdPessoa] [uniqueidentifier] NOT NULL ROWGUIDCOL,
--2)[NomeRazaoSocial] [varchar] (250) COLLATE Latin1_General_CI_AI NOT NULL,
--3)[NomeSocialFantasia] [varchar] (250) COLLATE Latin1_General_CI_AI NULL,
--4)[TipoPessoaFisica] [bit] NOT NULL CONSTRAINT [DEF_CadastroPessoasTipoPessoaFisica] DEFAULT ((1)),
--5)[CPFCNPJ] [varchar] (20) COLLATE Latin1_General_CI_AI NULL,
--6)[RGIE] [varchar] (30) COLLATE Latin1_General_CI_AI NULL,
--7)[Observacao] [varchar] (max) COLLATE Latin1_General_CI_AI NULL,
--8)[DataCriacao] [datetime] NULL,
--9)[DataAtualizacao] [datetime] NULL,
--10)[EnderecoSite] [varchar] (250) COLLATE Latin1_General_CI_AI NULL,
--11)[FlagsBitwisePessoa] [int] NOT NULL CONSTRAINT [DEF_CadastroPessoasFlagsBitwisePessoa] DEFAULT ((0)),
--12)[VisivelSomenteSiscaf] [bit] NOT NULL CONSTRAINT [DEF_CadastroPessoasVisivelSomenteSiscaf] DEFAULT ((0)),
--13)[NomeUsuarioChancela] [varchar] (250) COLLATE Latin1_General_CI_AI NULL,
--14)[DataChancela] [datetime] NULL,
--15)[Estrangeiro] [bit] NOT NULL CONSTRAINT [DEF_CadastroPessoasEstrangeiro] DEFAULT ((0)),
--16)[Ativo] [bit] NOT NULL CONSTRAINT [DEF_CadastroPessoasAtivo] DEFAULT ((1)),
--1)[EspecializacaoValor] [int] NOT NULL CONSTRAINT [DEF_CadastroPessoasEspecializacaoValor] DEFAULT ((0)),
--1)[NomeUsuarioCriacao] [varchar] (250) COLLATE Latin1_General_CI_AI NULL,
--1)[NomeUnidadeCriacao] [varchar] (60) COLLATE Latin1_General_CI_AI NULL,
--1)[NomeUsuarioAtualizacao] [varchar] (250) COLLATE Latin1_General_CI_AI NULL,
--1)[NomeUnidadeAtualizacao] [varchar] (60) COLLATE Latin1_General_CI_AI NULL
--) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]



--CREATE NONCLUSTERED INDEX [IX_Pessoas_NomeRazaoSocialEstrangeiroAtivo] ON [Cadastro].[Pessoas] ([NomeRazaoSocial], [Estrangeiro], [Ativo]) ON [PRIMARY]
--GO
--CREATE NONCLUSTERED INDEX [IX_Pessoas_NomeRazaoSocialEstrangeiroAtivoCPFCNPJ] ON [Cadastro].[Pessoas] ([NomeRazaoSocial], [Estrangeiro], [Ativo], [CPFCNPJ]) ON [PRIMARY]
--GO


