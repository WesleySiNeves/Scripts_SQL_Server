-- =====================================================
-- CURSO SQL SERVER - MÓDULO 03: FUNÇÕES E OPERADORES
-- Arquivo: 02_funcoes_conversao_null.sql
-- Tópico: Funções de Conversão e Tratamento de NULL
-- =====================================================

-- ÍNDICE:
-- 1. Tratamento de Valores NULL
-- 2. Funções de Conversão de Tipos
-- 3. Funções de Hash e Criptografia
-- 4. Validação e Verificação de Tipos
-- 5. Exercícios Práticos

-- =====================================================
-- 1. TRATAMENTO DE VALORES NULL
-- =====================================================

-- Exemplo 1: Diferença entre ISNULL e COALESCE
-- ISNULL faz tipagem implícita de dados
DECLARE @x AS VARCHAR(3) = NULL;
DECLARE @y AS VARCHAR(10) = '1234567890';

SELECT COALESCE(@x, @y) AS [COALESCE], -- Retorna VARCHAR(10)
       ISNULL(@x, @y) AS [ISNULL],     -- Retorna VARCHAR(3) - TRUNCADO!
       LEN(COALESCE(@x, @y)) AS TamanhoCoalesce,
       LEN(ISNULL(@x, @y)) AS TamanhoIsNull;

-- Exemplo 2: COALESCE com múltiplos valores
DECLARE @valor1 VARCHAR(10) = NULL;
DECLARE @valor2 VARCHAR(10) = NULL;
DECLARE @valor3 VARCHAR(10) = 'Terceiro';
DECLARE @valor4 VARCHAR(10) = 'Quarto';

SELECT COALESCE(@valor1, @valor2, @valor3, @valor4) AS PrimeiroNaoNulo;

-- ISNULL aceita apenas 2 parâmetros
SELECT ISNULL(@valor1, ISNULL(@valor2, ISNULL(@valor3, @valor4))) AS IsNullAninhado;

-- Exemplo 3: Tratamento de NULL em cálculos
DECLARE @preco DECIMAL(10,2) = 100.00;
DECLARE @desconto DECIMAL(10,2) = NULL;
DECLARE @taxa DECIMAL(10,2) = 0.05;

SELECT @preco AS PrecoOriginal,
       @desconto AS Desconto,
       @preco - @desconto AS CalculoComNull, -- Resultado será NULL
       @preco - ISNULL(@desconto, 0) AS CalculoComIsNull,
       @preco - COALESCE(@desconto, 0) AS CalculoComCoalesce,
       @preco * (1 - COALESCE(@taxa, 0)) AS PrecoComTaxa;

-- Exemplo 4: NULLIF - Retorna NULL se valores forem iguais
DECLARE @dividendo INT = 100;
DECLARE @divisor INT = 0;

SELECT @dividendo AS Dividendo,
       @divisor AS Divisor,
       @dividendo / NULLIF(@divisor, 0) AS DivisaoSegura, -- Evita divisão por zero
       CASE 
           WHEN @divisor = 0 THEN NULL 
           ELSE @dividendo / @divisor 
       END AS DivisaoComCase;

-- =====================================================
-- 2. FUNÇÕES DE CONVERSÃO DE TIPOS
-- =====================================================

-- Exemplo 1: CAST vs CONVERT
DECLARE @data_string VARCHAR(10) = '2024-01-15';
DECLARE @numero_string VARCHAR(10) = '123.45';
DECLARE @data_atual DATETIME = GETDATE();

SELECT -- Conversões básicas
       CAST(@data_string AS DATETIME) AS DataComCast,
       CONVERT(DATETIME, @data_string) AS DataComConvert,
       CAST(@numero_string AS DECIMAL(10,2)) AS NumeroComCast,
       CONVERT(DECIMAL(10,2), @numero_string) AS NumeroComConvert,
       
       -- CONVERT com estilos (apenas para datas)
       CONVERT(VARCHAR(10), @data_atual, 103) AS DataBrasileira, -- dd/mm/yyyy
       CONVERT(VARCHAR(10), @data_atual, 120) AS DataISO,        -- yyyy-mm-dd
       CONVERT(VARCHAR(8), @data_atual, 112) AS DataCompacta;    -- yyyymmdd

-- Exemplo 2: TRY_CAST e TRY_CONVERT (SQL Server 2012+)
DECLARE @valor_invalido VARCHAR(20) = 'ABC123';
DECLARE @data_invalida VARCHAR(20) = '32/13/2024';

SELECT @valor_invalido AS ValorOriginal,
       TRY_CAST(@valor_invalido AS INT) AS TentativaCast,
       TRY_CONVERT(INT, @valor_invalido) AS TentativaConvert,
       ISNULL(TRY_CAST(@valor_invalido AS INT), -1) AS ComTratamento,
       
       @data_invalida AS DataInvalida,
       TRY_CAST(@data_invalida AS DATETIME) AS TentativaDataCast,
       COALESCE(TRY_CAST(@data_invalida AS DATETIME), '1900-01-01') AS DataPadrao;

-- Exemplo 3: PARSE e TRY_PARSE (SQL Server 2012+)
DECLARE @valor_moeda VARCHAR(20) = 'R$ 1.234,56';
DECLARE @data_texto VARCHAR(20) = '15 de Janeiro de 2024';

SELECT @valor_moeda AS ValorMoeda,
       -- PARSE com cultura específica
       TRY_PARSE(@valor_moeda AS MONEY USING 'pt-BR') AS MoedaParsed,
       TRY_PARSE(@data_texto AS DATETIME USING 'pt-BR') AS DataParsed;

-- Exemplo 4: Conversões com validação
DECLARE @entrada VARCHAR(50) = '123.45';

SELECT @entrada AS Entrada,
       ISNUMERIC(@entrada) AS EhNumerico,
       ISDATE(@entrada) AS EhData,
       CASE 
           WHEN ISNUMERIC(@entrada) = 1 THEN TRY_CAST(@entrada AS DECIMAL(10,2))
           ELSE NULL
       END AS NumeroValidado,
       CASE 
           WHEN ISDATE(@entrada) = 1 THEN TRY_CAST(@entrada AS DATETIME)
           ELSE NULL
       END AS DataValidada;

-- =====================================================
-- 3. FUNÇÕES DE HASH E CRIPTOGRAFIA
-- =====================================================

-- Exemplo 1: HASHBYTES - Gerando hashes
DECLARE @texto VARCHAR(100) = 'SQL Server 2022';
DECLARE @senha VARCHAR(50) = 'MinhaSenh@123';

SELECT @texto AS TextoOriginal,
       HASHBYTES('MD5', @texto) AS HashMD5,
       HASHBYTES('SHA1', @texto) AS HashSHA1,
       HASHBYTES('SHA2_256', @texto) AS HashSHA256,
       HASHBYTES('SHA2_512', @texto) AS HashSHA512;

-- Exemplo 2: Uso prático - Detecção de duplicatas
IF OBJECT_ID('TEMPDB..#Documentos') IS NOT NULL
    DROP TABLE #Documentos;

CREATE TABLE #Documentos (
    Id INT IDENTITY(1,1),
    Nome VARCHAR(100),
    Conteudo VARCHAR(MAX),
    HashConteudo VARBINARY(32)
);

-- Inserindo documentos
INSERT INTO #Documentos (Nome, Conteudo, HashConteudo)
VALUES 
('Doc1.txt', 'Conteúdo do documento 1', HASHBYTES('SHA2_256', 'Conteúdo do documento 1')),
('Doc2.txt', 'Conteúdo do documento 2', HASHBYTES('SHA2_256', 'Conteúdo do documento 2')),
('Doc3.txt', 'Conteúdo do documento 1', HASHBYTES('SHA2_256', 'Conteúdo do documento 1')); -- Duplicata

-- Encontrando duplicatas por hash
SELECT HashConteudo,
       COUNT(*) AS QuantidadeDuplicatas,
       STRING_AGG(Nome, ', ') AS ArquivosDuplicados
FROM #Documentos
GROUP BY HashConteudo
HAVING COUNT(*) > 1;

DROP TABLE #Documentos;

-- Exemplo 3: Comparação de performance - Hash vs String
IF OBJECT_ID('TEMPDB..#TestePerfomance') IS NOT NULL
    DROP TABLE #TestePerfomance;

CREATE TABLE #TestePerfomance (
    Id INT IDENTITY(1,1),
    ConteudoTexto VARCHAR(1000),
    HashConteudo VARBINARY(32)
);

-- Inserindo dados de teste
DECLARE @i INT = 1;
WHILE @i <= 1000
BEGIN
    DECLARE @conteudo VARCHAR(1000) = 'Conteúdo de teste número ' + CAST(@i AS VARCHAR(10)) + REPLICATE(' Texto adicional', @i % 10);
    INSERT INTO #TestePerfomance (ConteudoTexto, HashConteudo)
    VALUES (@conteudo, HASHBYTES('SHA2_256', @conteudo));
    SET @i = @i + 1;
END

-- Comparação de busca
DECLARE @busca VARCHAR(1000) = 'Conteúdo de teste número 500 Texto adicional Texto adicional Texto adicional Texto adicional Texto adicional Texto adicional Texto adicional Texto adicional Texto adicional';
DECLARE @hash_busca VARBINARY(32) = HASHBYTES('SHA2_256', @busca);

-- Busca por string (mais lenta)
SELECT COUNT(*) AS ResultadoString
FROM #TestePerfomance
WHERE ConteudoTexto = @busca;

-- Busca por hash (mais rápida)
SELECT COUNT(*) AS ResultadoHash
FROM #TestePerfomance
WHERE HashConteudo = @hash_busca;

DROP TABLE #TestePerfomance;

-- =====================================================
-- 4. VALIDAÇÃO E VERIFICAÇÃO DE TIPOS
-- =====================================================

-- Exemplo 1: Funções de validação
DECLARE @valores TABLE (
    Id INT,
    Valor VARCHAR(50)
);

INSERT INTO @valores VALUES
(1, '123'),
(2, '123.45'),
(3, 'ABC'),
(4, '2024-01-15'),
(5, '32/13/2024'),
(6, ''),
(7, NULL);

SELECT Id,
       Valor,
       ISNUMERIC(Valor) AS EhNumerico,
       ISDATE(Valor) AS EhData,
       CASE 
           WHEN Valor IS NULL THEN 'NULL'
           WHEN LEN(TRIM(Valor)) = 0 THEN 'VAZIO'
           WHEN ISNUMERIC(Valor) = 1 THEN 'NUMERO'
           WHEN ISDATE(Valor) = 1 THEN 'DATA'
           ELSE 'TEXTO'
       END AS TipoDetectado,
       TRY_CAST(Valor AS INT) AS ComoInteiro,
       TRY_CAST(Valor AS DECIMAL(10,2)) AS ComoDecimal,
       TRY_CAST(Valor AS DATETIME) AS ComoData
FROM @valores;

-- Exemplo 2: Validação de CPF/CNPJ
DECLARE @documentos TABLE (
    Documento VARCHAR(20),
    Tipo VARCHAR(10)
);

INSERT INTO @documentos VALUES
('123.456.789-01', 'CPF'),
('12.345.678/0001-90', 'CNPJ'),
('12345678901', 'CPF_SEM_FORMATO'),
('ABC123', 'INVALIDO');

SELECT Documento,
       Tipo,
       -- Remover formatação
       REPLACE(REPLACE(REPLACE(REPLACE(Documento, '.', ''), '-', ''), '/', ''), ' ', '') AS SemFormatacao,
       -- Validar tamanho
       CASE 
           WHEN LEN(REPLACE(REPLACE(REPLACE(REPLACE(Documento, '.', ''), '-', ''), '/', ''), ' ', '')) = 11 
                AND ISNUMERIC(REPLACE(REPLACE(REPLACE(REPLACE(Documento, '.', ''), '-', ''), '/', ''), ' ', '')) = 1
           THEN 'CPF_VALIDO'
           WHEN LEN(REPLACE(REPLACE(REPLACE(REPLACE(Documento, '.', ''), '-', ''), '/', ''), ' ', '')) = 14 
                AND ISNUMERIC(REPLACE(REPLACE(REPLACE(REPLACE(Documento, '.', ''), '-', ''), '/', ''), ' ', '')) = 1
           THEN 'CNPJ_VALIDO'
           ELSE 'INVALIDO'
       END AS StatusValidacao
FROM @documentos;

-- Exemplo 3: Limpeza e padronização de dados
DECLARE @dados_sujos TABLE (
    Id INT,
    Nome VARCHAR(100),
    Email VARCHAR(100),
    Telefone VARCHAR(20),
    Valor VARCHAR(20)
);

INSERT INTO @dados_sujos VALUES
(1, '  JOÃO DA SILVA  ', 'joao@EMPRESA.com.BR', '(11) 99999-8888', 'R$ 1.234,56'),
(2, 'maria santos', 'MARIA@empresa.COM', '11999998888', '1234.56'),
(3, 'Pedro Oliveira', 'pedro@empresa', '(11)99999-8888', 'ABC');

SELECT Id,
       -- Limpeza de nomes
       LTRIM(RTRIM(Nome)) AS NomeLimpo,
       UPPER(LEFT(LTRIM(RTRIM(Nome)), 1)) + LOWER(SUBSTRING(LTRIM(RTRIM(Nome)), 2, LEN(Nome))) AS NomeFormatado,
       
       -- Limpeza de emails
       LOWER(LTRIM(RTRIM(Email))) AS EmailLimpo,
       CASE 
           WHEN CHARINDEX('@', Email) > 0 AND CHARINDEX('.', Email) > CHARINDEX('@', Email)
           THEN 'VALIDO'
           ELSE 'INVALIDO'
       END AS EmailStatus,
       
       -- Limpeza de telefones
       REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Telefone, '(', ''), ')', ''), '-', ''), ' ', ''), '.', '') AS TelefoneLimpo,
       
       -- Limpeza de valores
       REPLACE(REPLACE(REPLACE(Valor, 'R$', ''), '.', ''), ',', '.') AS ValorLimpo,
       TRY_CAST(REPLACE(REPLACE(REPLACE(Valor, 'R$', ''), '.', ''), ',', '.') AS DECIMAL(10,2)) AS ValorNumerico
FROM @dados_sujos;

-- =====================================================
-- 5. EXERCÍCIOS PRÁTICOS
-- =====================================================

/*
EXERCÍCIO 1:
Crie uma consulta que trate valores NULL em uma tabela de vendas,
substituindo NULL por valores padrão apropriados

EXERCÍCIO 2:
Implemente uma função que valide se uma string pode ser convertida
para um tipo específico (INT, DECIMAL, DATETIME)

EXERCÍCIO 3:
Crie uma consulta que detecte registros duplicados usando HASHBYTES

EXERCÍCIO 4:
Implemente uma rotina de limpeza de dados que:
- Remova espaços extras
- Padronize formato de telefones
- Valide emails
- Converta valores monetários

EXERCÍCIO 5:
Crie uma consulta que compare a performance entre:
- Busca por string completa
- Busca por hash da string
*/

-- =====================================================
-- SOLUÇÕES DOS EXERCÍCIOS
-- =====================================================

-- SOLUÇÃO 1:
/*
DECLARE @vendas TABLE (
    Id INT,
    Produto VARCHAR(50),
    Quantidade INT,
    Preco DECIMAL(10,2),
    Desconto DECIMAL(10,2)
);

SELECT Id,
       COALESCE(Produto, 'Produto não informado') AS Produto,
       ISNULL(Quantidade, 1) AS Quantidade,
       ISNULL(Preco, 0.00) AS Preco,
       ISNULL(Desconto, 0.00) AS Desconto,
       (ISNULL(Quantidade, 1) * ISNULL(Preco, 0.00)) * (1 - ISNULL(Desconto, 0.00)) AS Total
FROM @vendas;
*/

-- SOLUÇÃO 2:
/*
CREATE FUNCTION dbo.ValidarTipo(@valor VARCHAR(100), @tipo VARCHAR(20))
RETURNS BIT
AS
BEGIN
    DECLARE @resultado BIT = 0;
    
    IF @tipo = 'INT'
        SET @resultado = CASE WHEN TRY_CAST(@valor AS INT) IS NOT NULL THEN 1 ELSE 0 END;
    ELSE IF @tipo = 'DECIMAL'
        SET @resultado = CASE WHEN TRY_CAST(@valor AS DECIMAL(18,2)) IS NOT NULL THEN 1 ELSE 0 END;
    ELSE IF @tipo = 'DATETIME'
        SET @resultado = CASE WHEN TRY_CAST(@valor AS DATETIME) IS NOT NULL THEN 1 ELSE 0 END;
    
    RETURN @resultado;
END
*/

-- SOLUÇÃO 3:
/*
WITH DuplicatasPorHash AS (
    SELECT HASHBYTES('SHA2_256', CONCAT(Campo1, Campo2, Campo3)) AS HashRegistro,
           COUNT(*) AS Quantidade
    FROM MinhaTabela
    GROUP BY HASHBYTES('SHA2_256', CONCAT(Campo1, Campo2, Campo3))
    HAVING COUNT(*) > 1
)
SELECT T.*
FROM MinhaTabela T
INNER JOIN DuplicatasPorHash D ON HASHBYTES('SHA2_256', CONCAT(T.Campo1, T.Campo2, T.Campo3)) = D.HashRegistro;
*/