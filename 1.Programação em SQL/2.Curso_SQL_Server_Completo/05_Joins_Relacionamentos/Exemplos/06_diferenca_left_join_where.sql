-- =============================================
-- Módulo 5: Joins e Relacionamentos
-- Arquivo: 06_diferenca_left_join_where.sql
-- Descrição: Diferença crucial entre LEFT JOIN com WHERE vs AND
-- Baseado no arquivo original: diferenca do Lef Join com where.sql
-- =============================================

-- =============================================
-- CONCEITO FUNDAMENTAL
-- =============================================
-- A posição da condição (WHERE vs AND) em LEFT JOIN 
-- produz resultados completamente diferentes!

-- =============================================
-- CENÁRIO 1: LEFT JOIN com WHERE
-- =============================================
-- Busca fornecedores do Japão e produtos que eles fornecem
-- Fornecedores sem produtos são INCLUÍDOS
-- Resultado: Apenas fornecedores do Japão

SELECT 
    S.companyname AS [Fornecedor],
    S.country AS [País],
    P.productid AS [ID Produto],
    P.productname AS [Nome Produto],
    P.unitprice AS [Preço Unitário]
FROM Production.Suppliers AS S
LEFT OUTER JOIN Production.Products AS P
    ON S.supplierid = P.supplierid
WHERE S.country = N'Japan';

-- =============================================
-- CENÁRIO 2: LEFT JOIN com AND
-- =============================================
-- Retorna TODOS os fornecedores
-- Mostra produtos apenas para fornecedores do Japão
-- Resultado: Todos os fornecedores, mas produtos só do Japão

SELECT 
    S.companyname AS [Fornecedor],
    S.country AS [País],
    P.productid AS [ID Produto],
    P.productname AS [Nome Produto],
    P.unitprice AS [Preço Unitário]
FROM Production.Suppliers AS S
LEFT OUTER JOIN Production.Products AS P
    ON S.supplierid = P.supplierid
   AND S.country = N'Japan';

-- =============================================
-- ANÁLISE DETALHADA DOS RESULTADOS
-- =============================================

-- Exemplo com dados AdventureWorks
-- Vamos usar Vendor (fornecedor) e PurchaseOrderHeader

-- CENÁRIO A: WHERE filtra APÓS o JOIN
SELECT 
    V.Name AS [Nome Fornecedor],
    V.CreditRating AS [Rating Crédito],
    POH.PurchaseOrderID AS [ID Pedido],
    POH.OrderDate AS [Data Pedido],
    POH.TotalDue AS [Valor Total]
FROM Purchasing.Vendor AS V
LEFT JOIN Purchasing.PurchaseOrderHeader AS POH
    ON V.BusinessEntityID = POH.VendorID
WHERE V.CreditRating = 1
ORDER BY V.Name;

-- CENÁRIO B: AND filtra DURANTE o JOIN
SELECT 
    V.Name AS [Nome Fornecedor],
    V.CreditRating AS [Rating Crédito],
    POH.PurchaseOrderID AS [ID Pedido],
    POH.OrderDate AS [Data Pedido],
    POH.TotalDue AS [Valor Total]
FROM Purchasing.Vendor AS V
LEFT JOIN Purchasing.PurchaseOrderHeader AS POH
    ON V.BusinessEntityID = POH.VendorID
   AND V.CreditRating = 1
ORDER BY V.Name;

-- =============================================
-- COMPARAÇÃO PRÁTICA
-- =============================================

-- Contagem de registros - WHERE
SELECT 
    COUNT(*) AS [Total Registros WHERE]
FROM Purchasing.Vendor AS V
LEFT JOIN Purchasing.PurchaseOrderHeader AS POH
    ON V.BusinessEntityID = POH.VendorID
WHERE V.CreditRating = 1;

-- Contagem de registros - AND
SELECT 
    COUNT(*) AS [Total Registros AND]
FROM Purchasing.Vendor AS V
LEFT JOIN Purchasing.PurchaseOrderHeader AS POH
    ON V.BusinessEntityID = POH.VendorID
   AND V.CreditRating = 1;

-- =============================================
-- CASOS PRÁTICOS DE USO
-- =============================================

-- Caso 1: Quero apenas clientes ativos e seus pedidos
-- (Clientes inativos não devem aparecer)
SELECT 
    C.CustomerID,
    C.AccountNumber,
    SOH.SalesOrderID,
    SOH.OrderDate
FROM Sales.Customer AS C
LEFT JOIN Sales.SalesOrderHeader AS SOH
    ON C.CustomerID = SOH.CustomerID
WHERE C.CustomerID IS NOT NULL  -- Condição de exemplo
ORDER BY C.CustomerID;

-- Caso 2: Quero todos os clientes, mas pedidos apenas de 2014
-- (Clientes sem pedidos em 2014 devem aparecer com NULL)
SELECT 
    C.CustomerID,
    C.AccountNumber,
    SOH.SalesOrderID,
    SOH.OrderDate
FROM Sales.Customer AS C
LEFT JOIN Sales.SalesOrderHeader AS SOH
    ON C.CustomerID = SOH.CustomerID
   AND YEAR(SOH.OrderDate) = 2014
ORDER BY C.CustomerID;

-- =============================================
-- EXERCÍCIOS PRÁTICOS
-- =============================================

-- Exercício 1: 
-- Encontre todos os produtos e suas categorias,
-- mas mostre apenas produtos com preço > 100
-- TODO: Use WHERE

-- Exercício 2:
-- Encontre todas as categorias e seus produtos,
-- mas mostre produtos apenas se preço > 100
-- TODO: Use AND no JOIN

-- Exercício 3:
-- Compare os resultados dos exercícios 1 e 2
-- Explique a diferença
-- TODO: Análise dos resultados

-- =============================================
-- RESUMO DAS DIFERENÇAS
-- =============================================
/*
WHERE:
- Filtra o resultado FINAL
- Elimina registros que não atendem à condição
- Pode "quebrar" o LEFT JOIN

AND (no JOIN):
- Filtra DURANTE o processo de junção
- Mantém todos os registros da tabela à esquerda
- Preserva a natureza do LEFT JOIN

REGRA DE OURO:
- Use WHERE quando quiser filtrar o resultado final
- Use AND quando quiser filtrar apenas a tabela à direita
*/