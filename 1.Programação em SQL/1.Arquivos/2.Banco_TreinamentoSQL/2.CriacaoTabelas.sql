DROP TABLE IF EXISTS dbo.Lancamentos
DROP TABLE IF EXISTS dbo.ContaBancaria




IF (OBJECT_ID('ContaBancaria', 'U') IS NULL)
BEGIN

    CREATE TABLE dbo.ContaBancaria
    (
        idContaBancaria UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT DEF_ContaBancariaidContaBancaria
                DEFAULT (NEWSEQUENTIALID()),
        NomeConta VARCHAR(30) NOT NULL,
        CONSTRAINT PK_ContaBancariaIdContaBancaria
            PRIMARY KEY (idContaBancaria)
    );


    INSERT dbo.ContaBancaria
    (
        NomeConta
    )
    VALUES
    ('CEF'),
    ('BB');

END;

IF (OBJECT_ID('Lancamentos', 'U') IS NULL)
BEGIN

    CREATE TABLE dbo.Lancamentos
    (
        idLancamento UNIQUEIDENTIFIER NOT NULL ROWGUIDCOL
            CONSTRAINT DEF_LancamentosIdLancamento
                DEFAULT (NEWSEQUENTIALID()),
        idContaBancaria UNIQUEIDENTIFIER NOT NULL,
        Historico VARCHAR(100) NOT NULL
            CONSTRAINT DEF_LancamentosHistorico
                DEFAULT ('Historico padrão para lançamentos bancários.'),
        NumeroLancamento INT NOT NULL,
        Data DATETIME2(2) NOT NULL,
        Valor DECIMAL(18, 2) NOT NULL,
        Credito BIT NOT NULL,
        CONSTRAINT PK_Lancamentos
            PRIMARY KEY (idLancamento)
    );

    ALTER TABLE dbo.Lancamentos
    ADD CONSTRAINT FK_Lancamentos_Contem_ContaBancaria
        FOREIGN KEY (idContaBancaria)
        REFERENCES dbo.ContaBancaria (idContaBancaria);
END;







-- ==================================================================
--Observa��o:faz insert dos dados com valoes aleatorios
-- ==================================================================


DECLARE @dataInicio DATETIME = '2011-01-01';
DECLARE @IsCredito BIT = 1;
DECLARE @IdContaBancariaCEF UNIQUEIDENTIFIER =
        (
            SELECT TOP 1
                   CB.idContaBancaria
            FROM dbo.ContaBancaria AS CB
            WHERE CB.NomeConta = 'CEF'
        );
DECLARE @IdContaBancariaBB UNIQUEIDENTIFIER =
        (
            SELECT TOP 1
                   CB.idContaBancaria
            FROM dbo.ContaBancaria AS CB
            WHERE CB.NomeConta = 'BB'
        );


WITH CTE
AS (SELECT 1 AS NumeroLancamento
    UNION ALL
    SELECT CTE.NumeroLancamento + 1
    FROM CTE
    WHERE CTE.NumeroLancamento < 3000000),
     Query
AS (SELECT CTE.NumeroLancamento,
           TA.IdConta,
           TA.Data,
           TA.Valor,
           TA.Credito
    FROM CTE
        CROSS APPLY
    (
        SELECT CASE
                   WHEN (CTE.NumeroLancamento % 2 = 0) THEN
                       @IdContaBancariaCEF
                   ELSE
                       @IdContaBancariaBB
               END AS IdConta,
               CAST(DATEADD(
                               DAY,
                               ABS(CHECKSUM(NEWID()) % IIF((CTE.NumeroLancamento <= 800000), 2555, 730)),
                               IIF((CTE.NumeroLancamento <= 800000), '2011-01-01', '2022-01-01')
                           ) AS DATE) AS Data,
               CAST(ABS(CAST((CAST(CHECKSUM(NEWID()) AS DECIMAL(18, 2)) / 1000000) AS DECIMAL(18, 2))) AS DECIMAL(18, 2)) AS Valor,
               IIF((CTE.NumeroLancamento <= 600000), 0, 1) AS Credito
    ) AS TA )
INSERT INTO dbo.Lancamentos WITH (TABLOCK)
(
    idContaBancaria,
    NumeroLancamento,
    Data,
    Valor,
    Credito
)
SELECT Q.IdConta,
       Q.NumeroLancamento,
       Q.Data,
       Q.Valor,
       Q.Credito
FROM Query Q
OPTION (MAXRECURSION 0);




-- ==================================================================
-- Vamos analisar a quantidade de dados que temos por ano
-- ==================================================================

SELECT Ano = YEAR(L.Data),
       QuantidadeLancamento = FORMAT(COUNT(*), 'N', 'pt-Br')
FROM dbo.Lancamentos AS L
GROUP BY YEAR(L.Data)
ORDER BY YEAR(L.Data);


-- ==================================================================
-- Criação de novas tabelas para complementar o modelo
-- ==================================================================

-- Tabela de Categorias para classificar lançamentos
IF (OBJECT_ID('Categorias', 'U') IS NULL)
BEGIN
    CREATE TABLE dbo.Categorias
    (
        idCategoria UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT DEF_CategoriasIdCategoria
                DEFAULT (NEWSEQUENTIALID()),
        NomeCategoria VARCHAR(50) NOT NULL,
        Descricao VARCHAR(200) NULL,
        DataCriacao DATETIME2(2) NOT NULL DEFAULT (GETDATE()),
        Ativo BIT NOT NULL DEFAULT (1),
        CONSTRAINT PK_Categorias
            PRIMARY KEY (idCategoria)
    );

    -- Inserir algumas categorias padrão
    INSERT dbo.Categorias
    (
        NomeCategoria,
        Descricao
    )
    VALUES
    ('Alimentação', 'Gastos com restaurantes, mercado e delivery'),
    ('Transporte', 'Combustível, transporte público, aplicativos de mobilidade'),
    ('Moradia', 'Aluguel, contas de água, luz, internet, etc'),
    ('Saúde', 'Consultas médicas, medicamentos, plano de saúde'),
    ('Educação', 'Cursos, livros, material escolar'),
    ('Lazer', 'Cinema, viagens, hobbies'),
    ('Investimentos', 'Aplicações financeiras'),
    ('Salário', 'Recebimento de salário e benefícios'),
    ('Outros', 'Categorias diversas');
END;

-- Tabela para relacionar lançamentos com categorias
IF (OBJECT_ID('LancamentoCategorias', 'U') IS NULL)
BEGIN
    CREATE TABLE dbo.LancamentoCategorias
    (
        idLancamentoCategoria UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT DEF_LancamentoCategoriasIdLancamentoCategoria
                DEFAULT (NEWSEQUENTIALID()),
        idLancamento UNIQUEIDENTIFIER NOT NULL,
        idCategoria UNIQUEIDENTIFIER NOT NULL,
        Observacao VARCHAR(200) NULL,
        CONSTRAINT PK_LancamentoCategorias
            PRIMARY KEY (idLancamentoCategoria),
        CONSTRAINT FK_LancamentoCategorias_Lancamentos
            FOREIGN KEY (idLancamento)
            REFERENCES dbo.Lancamentos (idLancamento),
        CONSTRAINT FK_LancamentoCategorias_Categorias
            FOREIGN KEY (idCategoria)
            REFERENCES dbo.Categorias (idCategoria)
    );

    -- Criar um índice para melhorar a performance de consultas
    CREATE INDEX IX_LancamentoCategorias_IdLancamento
    ON dbo.LancamentoCategorias (idLancamento);

    CREATE INDEX IX_LancamentoCategorias_IdCategoria
    ON dbo.LancamentoCategorias (idCategoria);
END;

-- Inserir algumas categorias aleatórias para os lançamentos existentes
-- Isso vai categorizar apenas uma amostra dos lançamentos para não sobrecarregar o banco
DECLARE @TotalLancamentos INT = 10000; -- Limitar a quantidade para não sobrecarregar

WITH LancamentosAmostra AS (
    SELECT TOP (@TotalLancamentos) 
           idLancamento,
           ROW_NUMBER() OVER (ORDER BY NEWID()) AS RowNum
    FROM dbo.Lancamentos
)
INSERT INTO dbo.LancamentoCategorias (idLancamento, idCategoria)
SELECT 
    L.idLancamento,
    (SELECT TOP 1 idCategoria FROM dbo.Categorias ORDER BY NEWID()) AS idCategoria
FROM LancamentosAmostra L;

-- ==================================================================
-- Consulta para verificar a distribuição de categorias nos lançamentos
-- ==================================================================

SELECT 
    C.NomeCategoria,
    COUNT(LC.idLancamentoCategoria) AS QuantidadeLancamentos,
    FORMAT(SUM(L.Valor), 'C', 'pt-BR') AS ValorTotal
FROM dbo.Categorias C
LEFT JOIN dbo.LancamentoCategorias LC ON C.idCategoria = LC.idCategoria
LEFT JOIN dbo.Lancamentos L ON LC.idLancamento = L.idLancamento
GROUP BY C.NomeCategoria
ORDER BY COUNT(LC.idLancamentoCategoria) DESC;