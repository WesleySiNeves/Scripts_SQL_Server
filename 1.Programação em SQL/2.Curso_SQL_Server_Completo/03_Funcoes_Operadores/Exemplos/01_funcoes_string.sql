-- =====================================================
-- CURSO SQL SERVER - MÓDULO 03: FUNÇÕES E OPERADORES
-- Arquivo: 01_funcoes_string.sql
-- Tópico: Funções de Manipulação de Strings
-- =====================================================

-- ÍNDICE:
-- 1. Funções Básicas de String
-- 2. Funções de Busca e Posição
-- 3. Concatenação e Agregação
-- 4. Formatação com FORMAT
-- 5. STRING_SPLIT e STRING_AGG
-- 6. Exercícios Práticos

-- =====================================================
-- 1. FUNÇÕES BÁSICAS DE MANIPULAÇÃO DE STRINGS
-- =====================================================

-- Exemplo 1: Funções de tamanho e extração
DECLARE @texto VARCHAR(50) = '  SQL Server 2022  ';

SELECT @texto AS TextoOriginal,
       LEN(@texto) AS Comprimento,
       LEN(LTRIM(RTRIM(@texto))) AS ComprimentoSemEspacos,
       LEFT(@texto, 5) AS PrimeirosCaracteres,
       RIGHT(@texto, 5) AS UltimosCaracteres,
       SUBSTRING(@texto, 3, 10) AS SubString,
       LTRIM(@texto) AS SemEspacosEsquerda,
       RTRIM(@texto) AS SemEspacosDireita,
       TRIM(@texto) AS SemEspacos; -- SQL Server 2017+

-- Exemplo 2: Transformações de case
DECLARE @nome VARCHAR(30) = 'joão da silva';

SELECT @nome AS NomeOriginal,
       UPPER(@nome) AS Maiusculo,
       LOWER(@nome) AS Minusculo,
       -- Primeira letra maiúscula (função personalizada)
       UPPER(LEFT(@nome, 1)) + LOWER(SUBSTRING(@nome, 2, LEN(@nome))) AS PrimeiraLetraMaiuscula;

-- Exemplo 3: Substituição e manipulação
DECLARE @frase VARCHAR(100) = 'O SQL Server é uma excelente ferramenta';

SELECT @frase AS FraseOriginal,
       REPLACE(@frase, 'SQL Server', 'Microsoft SQL Server') AS ComSubstituicao,
       REVERSE(@frase) AS FraseInvertida,
       STUFF(@frase, 3, 10, 'Microsoft') AS ComStuff; -- Substitui caracteres em posição específica

-- =====================================================
-- 2. FUNÇÕES DE BUSCA E POSIÇÃO
-- =====================================================

-- Exemplo 1: CHARINDEX - Encontrar posição de substring
DECLARE @email VARCHAR(50) = 'usuario@empresa.com.br';

SELECT @email AS Email,
       CHARINDEX('@', @email) AS PosicaoArroba,
       CHARINDEX('.', @email) AS PrimeiroPonto,
       CHARINDEX('.', @email, CHARINDEX('@', @email)) AS PontoAposArroba,
       LEFT(@email, CHARINDEX('@', @email) - 1) AS Usuario,
       SUBSTRING(@email, CHARINDEX('@', @email) + 1, LEN(@email)) AS Dominio;

-- Exemplo 2: PATINDEX - Busca com padrões
DECLARE @telefone VARCHAR(20) = 'Tel: (11) 99999-8888';

SELECT @telefone AS TelefoneCompleto,
       PATINDEX('%([0-9][0-9])%', @telefone) AS PosicaoDDD,
       PATINDEX('%[0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]%', @telefone) AS PosicaoNumero;

-- Exemplo 3: Extraindo informações com múltiplas funções
DECLARE @endereco VARCHAR(100) = 'Rua das Flores, 123 - Jardim Primavera - São Paulo - SP';

SELECT @endereco AS EnderecoCompleto,
       SUBSTRING(@endereco, 1, CHARINDEX(',', @endereco) - 1) AS Rua,
       LTRIM(SUBSTRING(@endereco, 
                      CHARINDEX(',', @endereco) + 1, 
                      CHARINDEX('-', @endereco) - CHARINDEX(',', @endereco) - 1)) AS Numero;

-- =====================================================
-- 3. CONCATENAÇÃO E AGREGAÇÃO DE STRINGS
-- =====================================================

-- Exemplo 1: Diferentes formas de concatenação
DECLARE @nome_completo VARCHAR(50) = 'João';
DECLARE @sobrenome VARCHAR(50) = 'Silva';
DECLARE @idade INT = 30;

SELECT -- Concatenação tradicional (cuidado com NULL)
       @nome_completo + ' ' + @sobrenome AS Concatenacao1,
       -- CONCAT (trata NULL automaticamente)
       CONCAT(@nome_completo, ' ', @sobrenome) AS Concatenacao2,
       -- CONCAT_WS (com separador)
       CONCAT_WS(' ', @nome_completo, @sobrenome) AS Concatenacao3,
       -- Incluindo números
       CONCAT(@nome_completo, ' tem ', @idade, ' anos') AS ComNumero;

-- Exemplo 2: STRING_AGG - Agregação de strings (SQL Server 2017+)
DECLARE @TABELA TABLE (
    CODIGO INT,
    CLIENTE VARCHAR(25),
    PRODUTO VARCHAR(25)
);

-- Inserindo dados de exemplo
INSERT INTO @TABELA VALUES
(1, 'JORGE', 'Piso'),
(1, 'JORGE', 'Porta'),
(1, 'JORGE', 'Torneira'),
(2, 'MARIA', 'Carriola'),
(2, 'MARIA', 'Torneira');

-- Usando STRING_AGG (SQL Server 2017+)
SELECT CODIGO,
       CLIENTE,
       STRING_AGG(PRODUTO, '; ') AS ProdutosStringAgg
FROM @TABELA
GROUP BY CODIGO, CLIENTE;

-- Exemplo 3: Método alternativo com FOR XML (versões anteriores)
SELECT CODIGO,
       CLIENTE,
       STUFF((
           SELECT '; ' + PRODUTO
           FROM @TABELA AS T2
           WHERE T2.CODIGO = T1.CODIGO 
             AND T2.CLIENTE = T1.CLIENTE
           FOR XML PATH(''), TYPE
       ).value('.', 'VARCHAR(MAX)'), 1, 2, '') AS ProdutosXML
FROM @TABELA AS T1
GROUP BY CODIGO, CLIENTE;

-- =====================================================
-- 4. FORMATAÇÃO COM FORMAT
-- =====================================================

-- Exemplo 1: Formatação de números
DECLARE @numero DECIMAL(10,2) = 1234.56;
DECLARE @produto_id INT = 42;

SELECT @numero AS NumeroOriginal,
       FORMAT(@numero, 'C', 'pt-BR') AS Moeda, -- Formato de moeda brasileira
       FORMAT(@numero, 'N2', 'pt-BR') AS NumeroFormatado, -- Número com 2 decimais
       FORMAT(@numero, '0000.00') AS ComZeros, -- Formato personalizado
       FORMAT(@produto_id, 'd10') AS ProdutoComZeros; -- ID com 10 dígitos

-- Exemplo 2: Formatação de datas
DECLARE @data DATETIME = GETDATE();

SELECT @data AS DataOriginal,
       FORMAT(@data, 'dd/MM/yyyy') AS DataBrasileira,
       FORMAT(@data, 'yyyy-MM-dd') AS DataISO,
       FORMAT(@data, 'dddd, dd \de MMMM \de yyyy', 'pt-BR') AS DataPorExtenso,
       FORMAT(@data, 'HH:mm:ss') AS ApenasHora;

-- Exemplo 3: Formatação personalizada
DECLARE @valor MONEY = 15678.90;

SELECT @valor AS ValorOriginal,
       FORMAT(@valor, 'C0', 'pt-BR') AS MoedaSemCentavos,
       FORMAT(@valor, '#,##0.00') AS ComSeparadorMilhar,
       'R$ ' + FORMAT(@valor, '#,##0.00') AS MoedaPersonalizada;

-- =====================================================
-- 5. STRING_SPLIT E MANIPULAÇÃO DE LISTAS
-- =====================================================

-- Exemplo 1: STRING_SPLIT básico (SQL Server 2016+)
DECLARE @lista VARCHAR(100) = '1,4,9,1000,2009';

SELECT value AS Numero,
       TRY_CAST(value AS INT) AS NumeroConvertido
FROM STRING_SPLIT(@lista, ',');

-- Exemplo 2: Encontrar valores não existentes em tabela
IF OBJECT_ID('TEMPDB..#Demonstracao') IS NOT NULL
    DROP TABLE #Demonstracao;

CREATE TABLE #Demonstracao (
    Numero INT NOT NULL,
    Letra CHAR(1)
);

INSERT INTO #Demonstracao (Numero, Letra)
VALUES (1, 'A'), (4, 'B'), (9, 'C'), (10, 'D');

DECLARE @parametros VARCHAR(100) = '1,4,9,1000,2009';

-- Valores que NÃO existem na tabela
SELECT CAST(S.value AS INT) AS NumeroNaoEncontrado
FROM STRING_SPLIT(@parametros, ',') AS S
LEFT JOIN #Demonstracao AS D ON CAST(S.value AS INT) = D.Numero
WHERE D.Numero IS NULL;

-- Valores que EXISTEM na tabela
SELECT D.Numero, D.Letra
FROM #Demonstracao AS D
INNER JOIN STRING_SPLIT(@parametros, ',') AS S ON D.Numero = CAST(S.value AS INT);

DROP TABLE #Demonstracao;

-- Exemplo 3: Método alternativo para versões anteriores ao SQL Server 2016
DECLARE @lista_antiga VARCHAR(100) = '1,4,9,1000,2009';

-- Usando CTE recursiva para split
WITH CTE_Split AS (
    SELECT 
        CASE 
            WHEN CHARINDEX(',', @lista_antiga) > 0 
            THEN LEFT(@lista_antiga, CHARINDEX(',', @lista_antiga) - 1)
            ELSE @lista_antiga
        END AS Item,
        CASE 
            WHEN CHARINDEX(',', @lista_antiga) > 0 
            THEN SUBSTRING(@lista_antiga, CHARINDEX(',', @lista_antiga) + 1, LEN(@lista_antiga))
            ELSE ''
        END AS Resto
    
    UNION ALL
    
    SELECT 
        CASE 
            WHEN CHARINDEX(',', Resto) > 0 
            THEN LEFT(Resto, CHARINDEX(',', Resto) - 1)
            ELSE Resto
        END,
        CASE 
            WHEN CHARINDEX(',', Resto) > 0 
            THEN SUBSTRING(Resto, CHARINDEX(',', Resto) + 1, LEN(Resto))
            ELSE ''
        END
    FROM CTE_Split
    WHERE Resto <> ''
)
SELECT Item, TRY_CAST(Item AS INT) AS NumeroConvertido
FROM CTE_Split
WHERE Item <> '';

-- =====================================================
-- 6. FUNÇÕES AVANÇADAS E CASOS ESPECIAIS
-- =====================================================

-- Exemplo 1: Remover espaços extras entre palavras
DECLARE @texto_espacos VARCHAR(100) = 'SQL    Server    tem    muitos     espaços';

-- Método para remover espaços extras
WHILE CHARINDEX('  ', @texto_espacos) > 0
BEGIN
    SET @texto_espacos = REPLACE(@texto_espacos, '  ', ' ');
END

SELECT @texto_espacos AS TextoLimpo;

-- Exemplo 2: Função para capitalizar primeira letra de cada palavra
DECLARE @nome_completo_lower VARCHAR(100) = 'joão da silva santos';
DECLARE @resultado VARCHAR(100) = '';
DECLARE @palavra VARCHAR(50);
DECLARE @posicao INT = 1;

WHILE @posicao <= LEN(@nome_completo_lower)
BEGIN
    IF SUBSTRING(@nome_completo_lower, @posicao, 1) = ' ' OR @posicao = 1
    BEGIN
        IF @posicao > 1
            SET @resultado = @resultado + ' ';
        
        SET @posicao = @posicao + CASE WHEN @posicao = 1 THEN 0 ELSE 1 END;
        
        -- Encontrar fim da palavra
        DECLARE @fim_palavra INT = CHARINDEX(' ', @nome_completo_lower, @posicao);
        IF @fim_palavra = 0 SET @fim_palavra = LEN(@nome_completo_lower) + 1;
        
        SET @palavra = SUBSTRING(@nome_completo_lower, @posicao, @fim_palavra - @posicao);
        SET @resultado = @resultado + UPPER(LEFT(@palavra, 1)) + LOWER(SUBSTRING(@palavra, 2, LEN(@palavra)));
        SET @posicao = @fim_palavra;
    END
    ELSE
        SET @posicao = @posicao + 1;
END

SELECT @nome_completo_lower AS Original, @resultado AS Capitalizado;

-- Exemplo 3: Validação de CPF usando funções de string
DECLARE @cpf VARCHAR(14) = '123.456.789-09';

-- Remover formatação
DECLARE @cpf_numeros VARCHAR(11) = REPLACE(REPLACE(REPLACE(@cpf, '.', ''), '-', ''), ' ', '');

SELECT @cpf AS CPFOriginal,
       @cpf_numeros AS CPFNumeros,
       LEN(@cpf_numeros) AS Tamanho,
       CASE 
           WHEN LEN(@cpf_numeros) = 11 AND ISNUMERIC(@cpf_numeros) = 1 
           THEN 'Formato válido'
           ELSE 'Formato inválido'
       END AS Validacao;

-- =====================================================
-- 7. EXERCÍCIOS PRÁTICOS
-- =====================================================

/*
EXERCÍCIO 1:
Crie uma consulta que extraia o nome de usuário e domínio 
do email 'usuario.teste@empresa.com.br'

EXERCÍCIO 2:
Dada a string 'João;Maria;Pedro;Ana', use STRING_SPLIT 
para criar uma tabela com uma linha para cada nome

EXERCÍCIO 3:
Formate o número 1234567.89 como:
- Moeda brasileira
- Número com separador de milhares
- Número com 4 casas decimais

EXERCÍCIO 4:
Crie uma função que conte quantas palavras existem 
na frase 'SQL Server é uma excelente ferramenta'

EXERCÍCIO 5:
Dada uma lista de produtos separados por vírgula,
crie uma consulta que retorne apenas os produtos 
que começam com a letra 'P'
*/

-- =====================================================
-- SOLUÇÕES DOS EXERCÍCIOS
-- =====================================================

-- SOLUÇÃO 1:
/*
DECLARE @email VARCHAR(50) = 'usuario.teste@empresa.com.br';
SELECT 
    LEFT(@email, CHARINDEX('@', @email) - 1) AS Usuario,
    SUBSTRING(@email, CHARINDEX('@', @email) + 1, LEN(@email)) AS Dominio;
*/

-- SOLUÇÃO 2:
/*
DECLARE @nomes VARCHAR(50) = 'João;Maria;Pedro;Ana';
SELECT value AS Nome
FROM STRING_SPLIT(@nomes, ';');
*/

-- SOLUÇÃO 3:
/*
DECLARE @valor DECIMAL(10,2) = 1234567.89;
SELECT 
    FORMAT(@valor, 'C', 'pt-BR') AS Moeda,
    FORMAT(@valor, 'N', 'pt-BR') AS ComSeparador,
    FORMAT(@valor, 'N4', 'pt-BR') AS QuatroCasas;
*/

-- SOLUÇÃO 4:
/*
DECLARE @frase VARCHAR(100) = 'SQL Server é uma excelente ferramenta';
SELECT LEN(@frase) - LEN(REPLACE(@frase, ' ', '')) + 1 AS QuantidadePalavras;
*/

-- SOLUÇÃO 5:
/*
DECLARE @produtos VARCHAR(100) = 'Piso,Porta,Torneira,Parafuso,Mesa';
SELECT value AS Produto
FROM STRING_SPLIT(@produtos, ',')
WHERE LEFT(LTRIM(value), 1) = 'P';
*/