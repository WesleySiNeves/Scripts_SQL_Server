-- =============================================
-- Módulo 2: Consultas Básicas
-- Arquivo: 02_where_operadores.sql
-- Descrição: Filtros e operadores WHERE
-- =============================================

-- Exemplo 1: Operadores de comparação básicos
SELECT 
    ProductID,
    Name,
    ListPrice
FROM Production.Product
WHERE ListPrice > 100;

-- Exemplo 2: Operador de igualdade
SELECT 
    ProductID,
    Name,
    Color
FROM Production.Product
WHERE Color = 'Red';

-- Exemplo 3: Operador de diferença
SELECT 
    ProductID,
    Name,
    Color
FROM Production.Product
WHERE Color <> 'Red'
   AND Color IS NOT NULL;

-- Exemplo 4: Operadores lógicos AND/OR
SELECT 
    ProductID,
    Name,
    ListPrice,
    Color
FROM Production.Product
WHERE ListPrice > 500 
   AND (Color = 'Red' OR Color = 'Blue');

-- Exemplo 5: Operador IN
SELECT 
    ProductID,
    Name,
    Color
FROM Production.Product
WHERE Color IN ('Red', 'Blue', 'Black', 'White');

-- Exemplo 6: Operador NOT IN
SELECT 
    ProductID,
    Name,
    Color
FROM Production.Product
WHERE Color NOT IN ('Red', 'Blue')
   AND Color IS NOT NULL;

-- Exemplo 7: Operador BETWEEN
SELECT 
    ProductID,
    Name,
    ListPrice
FROM Production.Product
WHERE ListPrice BETWEEN 100 AND 500;

-- Exemplo 8: Tratamento de valores NULL
SELECT 
    ProductID,
    Name,
    Color
FROM Production.Product
WHERE Color IS NULL;

-- Exemplo 9: Valores NOT NULL
SELECT 
    ProductID,
    Name,
    Color
FROM Production.Product
WHERE Color IS NOT NULL;

-- Exemplo 10: Operador LIKE básico
SELECT 
    ProductID,
    Name
FROM Production.Product
WHERE Name LIKE 'Mountain%';

-- Exemplo 11: LIKE com múltiplos wildcards
SELECT 
    ProductID,
    Name
FROM Production.Product
WHERE Name LIKE '%Bike%';

-- Exemplo 12: LIKE com underscore (_)
SELECT 
    ProductID,
    Name,
    ProductNumber
FROM Production.Product
WHERE ProductNumber LIKE 'BK-____-__';

-- Exemplo 13: Busca por nomes com acentos (baseado no arquivo existente)
SELECT 
    BusinessEntityID,
    FirstName,
    LastName
FROM Person.Person
WHERE FirstName LIKE '%ã%' 
   OR FirstName LIKE '%á%'
   OR FirstName LIKE '%é%'
   OR FirstName LIKE '%í%'
   OR FirstName LIKE '%ó%'
   OR FirstName LIKE '%ú%'
   OR FirstName LIKE '%ç%';

-- Exemplo 14: LIKE somente números (baseado no arquivo existente)
SELECT 
    ProductID,
    Name,
    ProductNumber
FROM Production.Product
WHERE ProductNumber LIKE '%[0-9]%'
   AND ProductNumber NOT LIKE '%[A-Z]%';

-- Exemplo 15: Múltiplos LIKES com OR
SELECT 
    ProductID,
    Name
FROM Production.Product
WHERE Name LIKE '%Mountain%'
   OR Name LIKE '%Road%'
   OR Name LIKE '%Touring%';

-- =============================================
-- EXERCÍCIOS PRÁTICOS
-- =============================================

-- Exercício 1: Produtos com preço entre 50 e 200
-- TODO: Escreva sua consulta aqui

-- Exercício 2: Produtos que NÃO são vermelhos, azuis ou pretos
-- TODO: Escreva sua consulta aqui

-- Exercício 3: Produtos cujo nome começa com 'Sport'
-- TODO: Escreva sua consulta aqui

-- Exercício 4: Produtos com cor definida e preço maior que 1000
-- TODO: Escreva sua consulta aqui