/*
==============================================================================
                    AULA COMPLETA: FUNÇÕES DE STRINGS EM T-SQL
                           Do Básico ao Avançado
==============================================================================

Esta aula aborda todas as principais funções de manipulação de strings no SQL Server,
desde operações básicas até técnicas avançadas de processamento de texto.

Tópicos Abordados:
1. Funções Básicas de String
2. Funções de Busca e Posicionamento
3. Funções de Formatação e Conversão
4. Operador LIKE e Wildcards
5. Funções Avançadas (STRING_AGG, STRING_SPLIT)
6. Técnicas de Concatenação
7. Manipulação de Espaços
8. Expressões Regulares com LIKE
9. Comparação: XML vs STRING_AGG
10. Exercícios Práticos
11. Dicas de Performance

==============================================================================
*/

-- Configuração inicial
USE EcommerceDB;
GO

/*
==============================================================================
                        1. FUNÇÕES BÁSICAS DE STRING
==============================================================================
*/

-- LEN - Retorna o comprimento da string
SELECT 
    NomeProduto,
    LEN(NomeProduto) AS TamanhoNome,
    Descricao,
    LEN(Descricao) AS TamanhoDescricao
FROM Produtos
WHERE NomeProduto IS NOT NULL;

-- LEFT e RIGHT - Extraem caracteres da esquerda ou direita
SELECT 
    NomeProduto,
    LEFT(NomeProduto, 10) AS PrimeirosCaracteres,
    RIGHT(NomeProduto, 5) AS UltimosCaracteres
FROM Produtos;

-- SUBSTRING - Extrai uma parte específica da string
SELECT 
    NomeProduto,
    SUBSTRING(NomeProduto, 1, 15) AS ParteNome,
    SUBSTRING(Descricao, 5, 20) AS ParteDescricao
FROM Produtos
WHERE Descricao IS NOT NULL;

-- UPPER, LOWER e PROPER (através de função personalizada)
SELECT 
    NomeProduto,
    UPPER(NomeProduto) AS NomeMaiusculo,
    LOWER(NomeProduto) AS NomeMinusculo
FROM Produtos;

/*
==============================================================================
                    2. FUNÇÕES DE BUSCA E POSICIONAMENTO
==============================================================================
*/

-- CHARINDEX - Encontra a posição de uma substring
SELECT 
    NomeProduto,
    CHARINDEX('a', NomeProduto) AS PosicaoPrimeiroA,
    CHARINDEX('o', NomeProduto) AS PosicaoPrimeiroO
FROM Produtos
WHERE CHARINDEX('a', NomeProduto) > 0;

-- PATINDEX - Busca com padrões (wildcards)
SELECT 
    NomeProduto,
    PATINDEX('%[0-9]%', NomeProduto) AS PosicaoPrimeiroNumero
FROM Produtos
WHERE PATINDEX('%[0-9]%', NomeProduto) > 0;

/*
==============================================================================
                    3. FUNÇÕES DE FORMATAÇÃO E CONVERSÃO
==============================================================================
*/

-- LTRIM, RTRIM e TRIM - Remove espaços
DECLARE @textoComEspacos VARCHAR(50) = '  Produto com espaços  ';

SELECT 
    @textoComEspacos AS Original,
    LTRIM(@textoComEspacos) AS SemEspacosEsquerda,
    RTRIM(@textoComEspacos) AS SemEspacosDireita,
    LTRIM(RTRIM(@textoComEspacos)) AS SemEspacosAmbos;

-- REPLACE - Substitui caracteres ou substrings
SELECT 
    NomeProduto,
    REPLACE(NomeProduto, 'a', '@') AS ComArroba,
    REPLACE(NomeProduto, ' ', '_') AS ComUnderline
FROM Produtos;

-- Técnica avançada: Remover espaços extras entre palavras
-- Baseado no arquivo "5.Remover Espacos entre palavras.sql"
DECLARE @texto VARCHAR(MAX) = 'Produto        com        muitos        espaços';

SELECT 
    @texto AS TextoOriginal,
    REPLACE(REPLACE(REPLACE(@texto, ' ', '<>'), '><', ''), '<>', ' ') AS TextoLimpo;

/*
==============================================================================
                        4. OPERADOR LIKE E WILDCARDS
==============================================================================
*/

-- Wildcards básicos
SELECT NomeProduto
FROM Produtos
WHERE NomeProduto LIKE 'C%';  -- Começa com 'C'

SELECT NomeProduto
FROM Produtos
WHERE NomeProduto LIKE '%o';  -- Termina com 'o'

SELECT NomeProduto
FROM Produtos
WHERE NomeProduto LIKE '%ar%'; -- Contém 'ar'

-- Wildcards com caracteres específicos
SELECT NomeProduto
FROM Produtos
WHERE NomeProduto LIKE '_a%';  -- Segunda letra é 'a'

-- LIKE com colchetes - Baseado no arquivo "LikeReverso.sql"
DECLARE @TabelaTeste TABLE (
    Codigo INT IDENTITY(1,1),
    Descricao VARCHAR(100)
);

INSERT INTO @TabelaTeste VALUES 
    ('PRODUTO CAPA - MANDALA AZUL E ROSA'),
    ('PRODUTO CAPA - MANDALA ROSA E ROSA'),
    ('ITEM USH ESPECIAL'),
    ('CAPA PROTETORA USH');

-- Busca por qualquer caractere dentro dos colchetes
SELECT * FROM @TabelaTeste
WHERE Descricao LIKE '%[CAPA]%';

SELECT * FROM @TabelaTeste
WHERE Descricao LIKE '%[USH]%';

-- LIKE para encontrar apenas números
SELECT NomeProduto
FROM Produtos
WHERE NomeProduto LIKE '%[0-9]%';

/*
==============================================================================
                    5. FUNÇÕES AVANÇADAS (SQL SERVER 2016+)
==============================================================================
*/

-- STRING_SPLIT - Divide uma string em linhas
-- Baseado no arquivo "8.Uso do STRING_SPLIT.sql"
DECLARE @ListaIDs VARCHAR(100) = '1,2,3,4,5';

SELECT 
    value AS ID,
    CAST(value AS INT) AS IDNumerico
FROM STRING_SPLIT(@ListaIDs, ',');

-- Exemplo prático: Buscar produtos por lista de IDs
DECLARE @ProdutoIDs VARCHAR(100) = '1,3,5';

SELECT P.ProdutoID, P.NomeProduto
FROM Produtos P
INNER JOIN (
    SELECT CAST(value AS INT) AS ID
    FROM STRING_SPLIT(@ProdutoIDs, ',')
) AS IDs ON P.ProdutoID = IDs.ID;

-- STRING_AGG - Concatena valores em uma string
-- Baseado nos arquivos "7.Duas Linhas em uma STRING_AGG.sql" e "STRING_AGG X Xml.sql"
SELECT 
    C.NomeCategoria,
    STRING_AGG(P.NomeProduto, ', ') AS ProdutosDaCategoria
FROM Categorias C
INNER JOIN Produtos P ON C.CategoriaID = P.CategoriaID
GROUP BY C.NomeCategoria;

-- STRING_AGG com ordenação
SELECT 
    C.NomeCategoria,
    STRING_AGG(P.NomeProduto, ', ') WITHIN GROUP (ORDER BY P.NomeProduto) AS ProdutosOrdenados
FROM Categorias C
INNER JOIN Produtos P ON C.CategoriaID = P.CategoriaID
GROUP BY C.NomeCategoria;

/*
==============================================================================
                        6. TÉCNICAS DE CONCATENAÇÃO
==============================================================================
*/

-- Concatenação simples com +
SELECT 
    NomeProduto + ' - ' + ISNULL(Descricao, 'Sem descrição') AS ProdutoCompleto
FROM Produtos;

-- CONCAT - Função mais segura (trata NULLs automaticamente)
SELECT 
    CONCAT(NomeProduto, ' - R$ ', PrecoVenda) AS ProdutoComPreco
FROM Produtos;

-- CONCAT_WS - Concatena com separador
SELECT 
    CONCAT_WS(' | ', NomeProduto, 'Preço:', PrecoVenda, 'Estoque:', QuantidadeEstoque) AS InfoCompleta
FROM Produtos;

-- Comparação: XML vs STRING_AGG para concatenação
-- Método tradicional com XML (compatível com versões antigas)
SELECT 
    C.NomeCategoria,
    STUFF((
        SELECT ', ' + P.NomeProduto
        FROM Produtos P
        WHERE P.CategoriaID = C.CategoriaID
        ORDER BY P.NomeProduto
        FOR XML PATH(''), TYPE
    ).value('.[1]', 'NVARCHAR(MAX)'), 1, 2, '') AS ProdutosXML
FROM Categorias C;

-- Método moderno com STRING_AGG (SQL Server 2017+)
SELECT 
    C.NomeCategoria,
    STRING_AGG(P.NomeProduto, ', ') WITHIN GROUP (ORDER BY P.NomeProduto) AS ProdutosStringAgg
FROM Categorias C
INNER JOIN Produtos P ON C.CategoriaID = P.CategoriaID
GROUP BY C.NomeCategoria;

/*
==============================================================================
                        7. MANIPULAÇÃO AVANÇADA DE ESPAÇOS
==============================================================================
*/

GO
-- Função para remover espaços extras (baseada no arquivo original)
CREATE FUNCTION dbo.RemoverEspacosExtras(@texto VARCHAR(MAX))
RETURNS VARCHAR(MAX)
AS
BEGIN
    -- Remove espaços no início e fim
    SET @texto = LTRIM(RTRIM(@texto));
    
    -- Remove espaços extras entre palavras
    WHILE CHARINDEX('  ', @texto) > 0
    BEGIN
        SET @texto = REPLACE(@texto, '  ', ' ');
    END
    
    RETURN @texto;
END;
GO

-- Teste da função
SELECT dbo.RemoverEspacosExtras('  Produto    com    muitos     espaços  ') AS TextoLimpo;

/*
==============================================================================
                        8. FUNÇÃO PERSONALIZADA DE SPLIT
==============================================================================
*/

GO
-- Função de Split personalizada (baseada no arquivo "8.Uso do STRING_SPLIT.sql")
-- Útil para versões anteriores ao SQL Server 2016
CREATE FUNCTION dbo.SplitString(
    @texto VARCHAR(MAX),
    @delimiter NVARCHAR(5)
)
RETURNS @Resultado TABLE (Valor VARCHAR(MAX))
AS
BEGIN
    DECLARE @textXML XML;
    
    SET @textXML = CAST('<item>' + REPLACE(@texto, @delimiter, '</item><item>') + '</item>' AS XML);
    
    INSERT INTO @Resultado
    SELECT LTRIM(RTRIM(T.item.value('.', 'VARCHAR(MAX)')))
    FROM @textXML.nodes('/item') T(item)
    WHERE T.item.value('.', 'VARCHAR(MAX)') <> '';
    
    RETURN;
END;
GO

-- Teste da função de split
SELECT * FROM dbo.SplitString('Produto1,Produto2,Produto3', ',');

/*
==============================================================================
                        9. VALIDAÇÃO E LIMPEZA DE DADOS
==============================================================================
*/

GO
-- Função para validar se string contém apenas números
CREATE FUNCTION dbo.ApenasNumeros(@texto VARCHAR(MAX))
RETURNS BIT
AS
BEGIN
    IF @texto IS NULL OR @texto = ''
        RETURN 0;
    
    IF @texto NOT LIKE '%[^0-9]%'
        RETURN 1;
    
    RETURN 0;
END;
GO

-- Teste da validação
SELECT 
    '12345' AS Texto,
    dbo.ApenasNumeros('12345') AS ApenasNumeros
UNION ALL
SELECT 
    '123a45' AS Texto,
    dbo.ApenasNumeros('123a45') AS ApenasNumeros;

GO
-- Função para extrair apenas números de uma string
CREATE FUNCTION dbo.ExtrairNumeros(@texto VARCHAR(MAX))
RETURNS VARCHAR(MAX)
AS
BEGIN
    DECLARE @resultado VARCHAR(MAX) = '';
    DECLARE @i INT = 1;
    DECLARE @char CHAR(1);
    
    WHILE @i <= LEN(@texto)
    BEGIN
        SET @char = SUBSTRING(@texto, @i, 1);
        IF @char LIKE '[0-9]'
            SET @resultado = @resultado + @char;
        SET @i = @i + 1;
    END
    
    RETURN @resultado;
END;
GO

-- Teste da extração de números
SELECT dbo.ExtrairNumeros('Produto123ABC456') AS ApenasNumeros;

/*
==============================================================================
                        10. CONSULTAS PRÁTICAS COM STRINGS
==============================================================================
*/

-- 1. Produtos com nomes que começam com vogal
SELECT NomeProduto
FROM Produtos
WHERE LEFT(UPPER(NomeProduto), 1) IN ('A', 'E', 'I', 'O', 'U');

-- 2. Produtos com descrições longas (mais de 50 caracteres)
SELECT 
    NomeProduto,
    LEN(Descricao) AS TamanhoDescricao,
    LEFT(Descricao, 50) + '...' AS DescricaoResumida
FROM Produtos
WHERE LEN(Descricao) > 50;

-- 3. Busca flexível por nome (ignorando acentos)
SELECT NomeProduto
FROM Produtos
WHERE NomeProduto COLLATE SQL_Latin1_General_CP1_CI_AI LIKE '%cafe%';

-- 4. Produtos agrupados por primeira letra
SELECT 
    LEFT(UPPER(NomeProduto), 1) AS PrimeiraLetra,
    COUNT(*) AS QuantidadeProdutos,
    STRING_AGG(NomeProduto, ', ') AS Produtos
FROM Produtos
GROUP BY LEFT(UPPER(NomeProduto), 1)
ORDER BY PrimeiraLetra;

-- 5. Análise de palavras-chave em descrições
WITH PalavrasChave AS (
    SELECT 'qualidade' AS Palavra
    UNION ALL SELECT 'premium'
    UNION ALL SELECT 'especial'
    UNION ALL SELECT 'novo'
)
SELECT 
    pk.Palavra,
    COUNT(p.ProdutoID) AS ProdutosEncontrados
FROM PalavrasChave pk
LEFT JOIN Produtos p ON p.Descricao LIKE '%' + pk.Palavra + '%'
GROUP BY pk.Palavra;

/*
==============================================================================
                        11. EXERCÍCIOS PRÁTICOS
==============================================================================
*/

-- EXERCÍCIO 1: Criar um código de produto baseado no nome
-- Formato: Primeiras 3 letras + últimos 3 dígitos do ID
SELECT 
    ProdutoID,
    NomeProduto,
    UPPER(LEFT(REPLACE(NomeProduto, ' ', ''), 3)) + 
    RIGHT('000' + CAST(ProdutoID AS VARCHAR), 3) AS CodigoProduto
FROM Produtos;

-- EXERCÍCIO 2: Validar e limpar dados de entrada
DECLARE @DadosEntrada TABLE (
    ID INT IDENTITY,
    NomeOriginal VARCHAR(100)
);

INSERT INTO @DadosEntrada VALUES
    ('  Produto  com   espaços  '),
    ('PRODUTO EM MAIÚSCULA'),
    ('produto em minúscula'),
    ('Produto123ComNumeros');

SELECT 
    NomeOriginal,
    dbo.RemoverEspacosExtras(NomeOriginal) AS NomeLimpo,
    UPPER(LEFT(dbo.RemoverEspacosExtras(NomeOriginal), 1)) + 
    LOWER(SUBSTRING(dbo.RemoverEspacosExtras(NomeOriginal), 2, LEN(dbo.RemoverEspacosExtras(NomeOriginal)))) AS NomeFormatado
FROM @DadosEntrada;

-- EXERCÍCIO 3: Análise de padrões em nomes de produtos
SELECT 
    'Contém números' AS Categoria,
    COUNT(*) AS Quantidade
FROM Produtos
WHERE NomeProduto LIKE '%[0-9]%'
UNION ALL
SELECT 
    'Apenas letras' AS Categoria,
    COUNT(*) AS Quantidade
FROM Produtos
WHERE NomeProduto NOT LIKE '%[0-9]%'
UNION ALL
SELECT 
    'Contém hífen' AS Categoria,
    COUNT(*) AS Quantidade
FROM Produtos
WHERE NomeProduto LIKE '%-%';

/*
==============================================================================
                        12. DICAS DE PERFORMANCE
==============================================================================
*/

-- DICA 1: Use índices em colunas frequentemente pesquisadas com LIKE
-- CREATE INDEX IX_Produtos_NomeProduto ON Produtos(NomeProduto);

-- DICA 2: Para buscas que começam com wildcard (%), considere Full-Text Search
-- Em vez de: WHERE NomeProduto LIKE '%palavra%'
-- Use: WHERE CONTAINS(NomeProduto, 'palavra')

-- DICA 3: CHARINDEX é mais rápido que LIKE para buscas simples
-- Rápido:
SELECT * FROM Produtos WHERE CHARINDEX('Casa', NomeProduto) > 0;

-- Mais lento:
SELECT * FROM Produtos WHERE NomeProduto LIKE '%Casa%';

-- DICA 4: Use COLLATE apenas quando necessário
-- Pode impactar performance em grandes volumes

-- DICA 5: STRING_AGG é mais eficiente que XML PATH para concatenação
-- em SQL Server 2017+

/*
==============================================================================
                        13. LIMPEZA DE OBJETOS CRIADOS
==============================================================================
*/

-- Remover funções criadas durante a aula
IF OBJECT_ID('dbo.RemoverEspacosExtras') IS NOT NULL
    DROP FUNCTION dbo.RemoverEspacosExtras;

IF OBJECT_ID('dbo.SplitString') IS NOT NULL
    DROP FUNCTION dbo.SplitString;

IF OBJECT_ID('dbo.ApenasNumeros') IS NOT NULL
    DROP FUNCTION dbo.ApenasNumeros;

IF OBJECT_ID('dbo.ExtrairNumeros') IS NOT NULL
    DROP FUNCTION dbo.ExtrairNumeros;

/*
==============================================================================
                                RESUMO FINAL
==============================================================================

Funções Básicas Cobertas:
- LEN, LEFT, RIGHT, SUBSTRING
- UPPER, LOWER, LTRIM, RTRIM
- CHARINDEX, PATINDEX
- REPLACE, CONCAT, CONCAT_WS

Funções Avançadas:
- STRING_AGG, STRING_SPLIT
- LIKE com wildcards e colchetes
- Técnicas de concatenação (XML vs STRING_AGG)
- Funções personalizadas para manipulação

Técnicas Importantes:
- Remoção de espaços extras
- Validação de dados
- Busca flexível com COLLATE
- Análise de padrões

Dicas de Performance:
- Uso adequado de índices
- CHARINDEX vs LIKE
- Full-Text Search para buscas complexas
- STRING_AGG vs XML PATH

==============================================================================
*/