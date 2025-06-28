-- =============================================
-- Módulo 6: Subconsultas e CTEs
-- Arquivo: 04_ctes_nao_recursivas.sql
-- Descrição: Common Table Expressions não-recursivas
-- Baseado nos arquivos existentes de CTEs
-- =============================================

-- =============================================
-- EXEMPLO 1: CTE Básica Simples
-- =============================================
-- CTE não recursiva com ROW_NUMBER
-- Baseado no arquivo: 1.CTENaoRecursivaSimples.sql

WITH CTEQuery (categoryid, productid, productname, unitprice, RowNum)
AS (
    SELECT 
        Query.categoryid,
        Query.productid,
        Query.productname,
        Query.unitprice,
        Query.RowNum
    FROM (
        SELECT 
            ROW_NUMBER() OVER (PARTITION BY P.categoryid ORDER BY P.productid) AS RowNum,
            P.ProductID AS productid,
            P.Name AS productname,
            P.ProductSubcategoryID AS categoryid,
            P.ListPrice AS unitprice
        FROM Production.Product AS P
        WHERE P.ListPrice > 0
    ) AS Query
)
SELECT 
    CTEQuery.categoryid,
    CTEQuery.productid,
    CTEQuery.productname,
    CTEQuery.unitprice,
    CTEQuery.RowNum
FROM CTEQuery
ORDER BY CTEQuery.categoryid, CTEQuery.RowNum;

-- =============================================
-- EXEMPLO 2: CTE com Cálculo de Porcentagem
-- =============================================
-- CTE para calcular porcentagem sobre o valor total
-- Baseado no arquivo: 4.CTE Com Porcentagem sobre o valor Total.sql

WITH VendasPorCategoria AS (
    SELECT 
        PC.Name AS Categoria,
        SUM(SOD.LineTotal) AS TotalVendas
    FROM Sales.SalesOrderDetail SOD
    INNER JOIN Production.Product P ON SOD.ProductID = P.ProductID
    INNER JOIN Production.ProductSubcategory PSC ON P.ProductSubcategoryID = PSC.ProductSubcategoryID
    INNER JOIN Production.ProductCategory PC ON PSC.ProductCategoryID = PC.ProductCategoryID
    GROUP BY PC.Name
),
TotalGeral AS (
    SELECT SUM(TotalVendas) AS GrandTotal
    FROM VendasPorCategoria
)
SELECT 
    VPC.Categoria,
    VPC.TotalVendas,
    TG.GrandTotal,
    ROUND((VPC.TotalVendas * 100.0) / TG.GrandTotal, 2) AS PercentualDoTotal
FROM VendasPorCategoria VPC
CROSS JOIN TotalGeral TG
ORDER BY VPC.TotalVendas DESC;

-- =============================================
-- EXEMPLO 3: CTE com SUM OVER
-- =============================================
-- CTE utilizando funções de janela
-- Baseado no arquivo: 5.CTE Sum Over.sql

WITH VendasComAcumulado AS (
    SELECT 
        SOH.SalesOrderID,
        SOH.OrderDate,
        SOH.TotalDue,
        SUM(SOH.TotalDue) OVER (
            ORDER BY SOH.OrderDate 
            ROWS UNBOUNDED PRECEDING
        ) AS TotalAcumulado,
        SUM(SOH.TotalDue) OVER (
            PARTITION BY YEAR(SOH.OrderDate)
            ORDER BY SOH.OrderDate
            ROWS UNBOUNDED PRECEDING
        ) AS TotalAcumuladoAno
    FROM Sales.SalesOrderHeader SOH
    WHERE SOH.OrderDate >= '2014-01-01'
)
SELECT 
    SalesOrderID,
    OrderDate,
    TotalDue,
    TotalAcumulado,
    TotalAcumuladoAno,
    ROUND((TotalDue * 100.0) / TotalAcumulado, 2) AS PercentualAcumulado
FROM VendasComAcumulado
ORDER BY OrderDate;

-- =============================================
-- EXEMPLO 4: CTE para Maiores Empenhos por Pessoa
-- =============================================
-- Análise dos maiores valores por cliente
-- Baseado no arquivo: 2.CTENaoRecursivaMaiores10EmpenhosPorPessoa.sql

WITH MaioresVendasPorCliente AS (
    SELECT 
        C.CustomerID,
        P.FirstName + ' ' + P.LastName AS NomeCompleto,
        SOH.SalesOrderID,
        SOH.TotalDue,
        ROW_NUMBER() OVER (
            PARTITION BY C.CustomerID 
            ORDER BY SOH.TotalDue DESC
        ) AS RankingVenda
    FROM Sales.Customer C
    INNER JOIN Person.Person P ON C.PersonID = P.BusinessEntityID
    INNER JOIN Sales.SalesOrderHeader SOH ON C.CustomerID = SOH.CustomerID
    WHERE SOH.TotalDue > 1000
)
SELECT 
    CustomerID,
    NomeCompleto,
    SalesOrderID,
    TotalDue,
    RankingVenda
FROM MaioresVendasPorCliente
WHERE RankingVenda <= 10  -- Top 10 vendas por cliente
ORDER BY CustomerID, RankingVenda;

-- =============================================
-- EXEMPLO 5: CTE com Múltiplas Definições
-- =============================================
-- Múltiplas CTEs em uma única consulta

WITH 
-- CTE 1: Vendas por ano
VendasAnuais AS (
    SELECT 
        YEAR(OrderDate) AS Ano,
        COUNT(*) AS QtdePedidos,
        SUM(TotalDue) AS TotalVendas,
        AVG(TotalDue) AS MediaVendas
    FROM Sales.SalesOrderHeader
    GROUP BY YEAR(OrderDate)
),
-- CTE 2: Crescimento ano a ano
CrescimentoAnual AS (
    SELECT 
        Ano,
        QtdePedidos,
        TotalVendas,
        MediaVendas,
        LAG(TotalVendas) OVER (ORDER BY Ano) AS VendasAnoAnterior,
        TotalVendas - LAG(TotalVendas) OVER (ORDER BY Ano) AS CrescimentoAbsoluto
    FROM VendasAnuais
),
-- CTE 3: Percentual de crescimento
PercentualCrescimento AS (
    SELECT 
        *,
        CASE 
            WHEN VendasAnoAnterior IS NOT NULL AND VendasAnoAnterior > 0
            THEN ROUND((CrescimentoAbsoluto * 100.0) / VendasAnoAnterior, 2)
            ELSE NULL
        END AS PercentualCrescimento
    FROM CrescimentoAnual
)
SELECT 
    Ano,
    QtdePedidos,
    FORMAT(TotalVendas, 'C', 'pt-BR') AS TotalVendas,
    FORMAT(MediaVendas, 'C', 'pt-BR') AS MediaVendas,
    FORMAT(VendasAnoAnterior, 'C', 'pt-BR') AS VendasAnoAnterior,
    FORMAT(CrescimentoAbsoluto, 'C', 'pt-BR') AS CrescimentoAbsoluto,
    CAST(PercentualCrescimento AS VARCHAR(10)) + '%' AS PercentualCrescimento
FROM PercentualCrescimento
ORDER BY Ano;

-- =============================================
-- EXEMPLO 6: CTE com Análise Estatística
-- =============================================
-- Análise estatística de vendas por território

WITH EstatisticasTerritorios AS (
    SELECT 
        ST.Name AS Territorio,
        COUNT(SOH.SalesOrderID) AS QtdePedidos,
        SUM(SOH.TotalDue) AS TotalVendas,
        AVG(SOH.TotalDue) AS MediaVendas,
        MIN(SOH.TotalDue) AS MenorVenda,
        MAX(SOH.TotalDue) AS MaiorVenda,
        STDEV(SOH.TotalDue) AS DesvioPadrao,
        VAR(SOH.TotalDue) AS Variancia
    FROM Sales.SalesOrderHeader SOH
    INNER JOIN Sales.SalesTerritory ST ON SOH.TerritoryID = ST.TerritoryID
    GROUP BY ST.TerritoryID, ST.Name
),
ClassificacaoTerritorios AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY TotalVendas DESC) AS RankingVendas,
        NTILE(4) OVER (ORDER BY TotalVendas) AS Quartil,
        CASE 
            WHEN TotalVendas > (SELECT AVG(TotalVendas) FROM EstatisticasTerritorios)
            THEN 'Acima da Média'
            ELSE 'Abaixo da Média'
        END AS ClassificacaoMedia
    FROM EstatisticasTerritorios
)
SELECT 
    Territorio,
    QtdePedidos,
    FORMAT(TotalVendas, 'C', 'pt-BR') AS TotalVendas,
    FORMAT(MediaVendas, 'C', 'pt-BR') AS MediaVendas,
    FORMAT(MenorVenda, 'C', 'pt-BR') AS MenorVenda,
    FORMAT(MaiorVenda, 'C', 'pt-BR') AS MaiorVenda,
    ROUND(DesvioPadrao, 2) AS DesvioPadrao,
    RankingVendas,
    Quartil,
    ClassificacaoMedia
FROM ClassificacaoTerritorios
ORDER BY RankingVendas;

-- =============================================
-- EXERCÍCIOS PRÁTICOS
-- =============================================

-- Exercício 1: Crie uma CTE que calcule o ranking de produtos
-- por categoria baseado no total de vendas
-- TODO: Implemente aqui

-- Exercício 2: Use múltiplas CTEs para analisar a performance
-- de vendedores por trimestre
-- TODO: Implemente aqui

-- Exercício 3: Crie uma CTE que identifique clientes
-- com comportamento de compra irregular
-- TODO: Implemente aqui