-- =============================================
-- Módulo 2: Consultas Básicas
-- Arquivo: 01_select_basico.sql
-- Descrição: Exemplos fundamentais de SELECT
-- =============================================

-- Exemplo 1: SELECT básico - todas as colunas
SELECT * 
FROM Production.Product;

-- Exemplo 2: SELECT específico - colunas selecionadas
SELECT 
    ProductID,
    Name,
    ProductNumber,
    ListPrice
FROM Production.Product;

-- Exemplo 3: SELECT com aliases
SELECT 
    ProductID AS [ID do Produto],
    Name AS [Nome do Produto],
    ProductNumber AS [Código],
    ListPrice AS [Preço de Lista]
FROM Production.Product;

-- Exemplo 4: SELECT com expressões e cálculos
SELECT 
    ProductID,
    Name,
    ListPrice,
    ListPrice * 0.9 AS [Preço com Desconto 10%],
    CASE 
        WHEN ListPrice > 1000 THEN 'Caro'
        WHEN ListPrice > 100 THEN 'Médio'
        ELSE 'Barato'
    END AS [Categoria Preço]
FROM Production.Product;

-- Exemplo 5: SELECT DISTINCT - valores únicos
SELECT DISTINCT 
    Color
FROM Production.Product
WHERE Color IS NOT NULL;

-- Exemplo 6: SELECT com constantes
SELECT 
    'Produto: ' + Name AS [Descrição],
    ListPrice,
    'R$' AS [Moeda],
    GETDATE() AS [Data Consulta]
FROM Production.Product
WHERE ListPrice > 0;

-- Exemplo 7: SELECT com funções básicas
SELECT 
    ProductID,
    UPPER(Name) AS [Nome Maiúsculo],
    LOWER(Name) AS [Nome Minúsculo],
    LEN(Name) AS [Tamanho Nome],
    ROUND(ListPrice, 0) AS [Preço Arredondado]
FROM Production.Product
WHERE Name IS NOT NULL;

-- =============================================
-- EXERCÍCIOS PRÁTICOS
-- =============================================

-- Exercício 1: Selecione ID, Nome e Preço dos produtos
-- TODO: Escreva sua consulta aqui

-- Exercício 2: Crie aliases em português para as colunas
-- TODO: Escreva sua consulta aqui

-- Exercício 3: Calcule o preço com 15% de desconto
-- TODO: Escreva sua consulta aqui

-- Exercício 4: Liste todas as cores disponíveis (sem repetição)
-- TODO: Escreva sua consulta aqui