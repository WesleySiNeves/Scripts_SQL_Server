-- =============================================
-- Módulo 10: Window Functions
-- Arquivo: 04_funcoes_offset.sql
-- Descrição: LAG, LEAD, FIRST_VALUE, LAST_VALUE
-- Baseado nos arquivos existentes de Windows Functions
-- =============================================

-- =============================================
-- EXEMPLO 1: FIRST_VALUE e LAST_VALUE
-- =============================================
-- Baseado no arquivo: 1.Batida Ponto (Firt e Last Value).sql
-- Análise de horários de entrada e saída

WITH BatidaPonto AS (
    SELECT 
        BusinessEntityID AS FuncionarioID,
        CAST('2024-01-15' AS DATE) AS DataBatida,
        CAST('08:00:00' AS TIME) AS HoraBatida,
        'Entrada' AS TipoBatida
    UNION ALL
    SELECT BusinessEntityID, '2024-01-15', '12:00:00', 'Saída Almoço'
    FROM Person.Person WHERE BusinessEntityID <= 5
    UNION ALL
    SELECT BusinessEntityID, '2024-01-15', '13:00:00', 'Volta Almoço'
    FROM Person.Person WHERE BusinessEntityID <= 5
    UNION ALL
    SELECT BusinessEntityID, '2024-01-15', '18:00:00', 'Saída'
    FROM Person.Person WHERE BusinessEntityID <= 5
)
SELECT 
    FuncionarioID,
    DataBatida,
    HoraBatida,
    TipoBatida,
    -- Primeira batida do dia (entrada)
    FIRST_VALUE(HoraBatida) OVER (
        PARTITION BY FuncionarioID, DataBatida 
        ORDER BY HoraBatida
        ROWS UNBOUNDED PRECEDING
    ) AS PrimeiraBatida,
    -- Última batida do dia (saída)
    LAST_VALUE(HoraBatida) OVER (
        PARTITION BY FuncionarioID, DataBatida 
        ORDER BY HoraBatida
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS UltimaBatida,
    -- Cálculo de horas trabalhadas (simplificado)
    DATEDIFF(MINUTE, 
        FIRST_VALUE(HoraBatida) OVER (
            PARTITION BY FuncionarioID, DataBatida 
            ORDER BY HoraBatida
            ROWS UNBOUNDED PRECEDING
        ),
        LAST_VALUE(HoraBatida) OVER (
            PARTITION BY FuncionarioID, DataBatida 
            ORDER BY HoraBatida
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        )
    ) / 60.0 AS HorasTrabalhadasTotal
FROM BatidaPonto
ORDER BY FuncionarioID, HoraBatida;

-- =============================================
-- EXEMPLO 2: LAG e LEAD - Análise Temporal
-- =============================================
-- Comparação de vendas com períodos anteriores e posteriores

WITH VendasMensais AS (
    SELECT 
        YEAR(OrderDate) AS Ano,
        MONTH(OrderDate) AS Mes,
        COUNT(*) AS QtdePedidos,
        SUM(TotalDue) AS TotalVendas,
        AVG(TotalDue) AS MediaVendas
    FROM Sales.SalesOrderHeader
    WHERE OrderDate >= '2013-01-01'
    GROUP BY YEAR(OrderDate), MONTH(OrderDate)
)
SELECT 
    Ano,
    Mes,
    FORMAT(DATEFROMPARTS(Ano, Mes, 1), 'MMMM yyyy', 'pt-BR') AS PeriodoFormatado,
    QtdePedidos,
    FORMAT(TotalVendas, 'C', 'pt-BR') AS TotalVendas,
    
    -- Comparação com mês anterior
    LAG(TotalVendas, 1) OVER (ORDER BY Ano, Mes) AS VendasMesAnterior,
    TotalVendas - LAG(TotalVendas, 1) OVER (ORDER BY Ano, Mes) AS DiferencaMesAnterior,
    
    -- Comparação com próximo mês
    LEAD(TotalVendas, 1) OVER (ORDER BY Ano, Mes) AS VendasProximoMes,
    LEAD(TotalVendas, 1) OVER (ORDER BY Ano, Mes) - TotalVendas AS DiferencaProximoMes,
    
    -- Comparação com mesmo mês do ano anterior
    LAG(TotalVendas, 12) OVER (ORDER BY Ano, Mes) AS VendasMesmoMesAnoAnterior,
    
    -- Percentual de crescimento
    CASE 
        WHEN LAG(TotalVendas, 1) OVER (ORDER BY Ano, Mes) > 0
        THEN ROUND(
            ((TotalVendas - LAG(TotalVendas, 1) OVER (ORDER BY Ano, Mes)) * 100.0) / 
            LAG(TotalVendas, 1) OVER (ORDER BY Ano, Mes), 2
        )
        ELSE NULL
    END AS PercentualCrescimentoMensal,
    
    -- Tendência (crescimento/queda)
    CASE 
        WHEN TotalVendas > LAG(TotalVendas, 1) OVER (ORDER BY Ano, Mes) THEN '↗️ Crescimento'
        WHEN TotalVendas < LAG(TotalVendas, 1) OVER (ORDER BY Ano, Mes) THEN '↘️ Queda'
        WHEN TotalVendas = LAG(TotalVendas, 1) OVER (ORDER BY Ano, Mes) THEN '➡️ Estável'
        ELSE '🆕 Primeiro período'
    END AS Tendencia
FROM VendasMensais
ORDER BY Ano, Mes;

-- =============================================
-- EXEMPLO 3: Análise de Últimas N Vendas
-- =============================================
-- Baseado no arquivo: 2.Ultimas 3 vendas(PRECEDING AND CURRENT ROW).sql
-- Análise das últimas 3 vendas por cliente

WITH UltimasVendas AS (
    SELECT 
        SOH.CustomerID,
        P.FirstName + ' ' + ISNULL(P.LastName, '') AS NomeCliente,
        SOH.SalesOrderID,
        SOH.OrderDate,
        SOH.TotalDue,
        ROW_NUMBER() OVER (
            PARTITION BY SOH.CustomerID 
            ORDER BY SOH.OrderDate DESC
        ) AS RankingVenda
    FROM Sales.SalesOrderHeader SOH
    INNER JOIN Sales.Customer C ON SOH.CustomerID = C.CustomerID
    LEFT JOIN Person.Person P ON C.PersonID = P.BusinessEntityID
    WHERE SOH.OrderDate >= '2014-01-01'
)
SELECT 
    CustomerID,
    NomeCliente,
    SalesOrderID,
    OrderDate,
    FORMAT(TotalDue, 'C', 'pt-BR') AS TotalDue,
    RankingVenda,
    
    -- Valor da venda anterior
    LAG(TotalDue, 1) OVER (
        PARTITION BY CustomerID 
        ORDER BY OrderDate
    ) AS VendaAnterior,
    
    -- Diferença com venda anterior
    TotalDue - LAG(TotalDue, 1) OVER (
        PARTITION BY CustomerID 
        ORDER BY OrderDate
    ) AS DiferencaVendaAnterior,
    
    -- Média das últimas 3 vendas (incluindo atual)
    AVG(TotalDue) OVER (
        PARTITION BY CustomerID 
        ORDER BY OrderDate
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS MediaUltimas3Vendas,
    
    -- Maior valor das últimas 3 vendas
    MAX(TotalDue) OVER (
        PARTITION BY CustomerID 
        ORDER BY OrderDate
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS MaiorUltimas3Vendas,
    
    -- Menor valor das últimas 3 vendas
    MIN(TotalDue) OVER (
        PARTITION BY CustomerID 
        ORDER BY OrderDate
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS MenorUltimas3Vendas
FROM UltimasVendas
WHERE RankingVenda <= 5  -- Últimas 5 vendas por cliente
ORDER BY CustomerID, OrderDate DESC;

-- =============================================
-- EXEMPLO 4: Análise de Preços - Comparação Relativa
-- =============================================
-- Baseado no arquivo: 6.Porcentagem Relativa do preco atual com o proximo preço.sql

WITH ProdutosComPrecos AS (
    SELECT 
        P.ProductID,
        P.Name AS NomeProduto,
        PSC.Name AS Subcategoria,
        PC.Name AS Categoria,
        P.ListPrice,
        P.StandardCost
    FROM Production.Product P
    LEFT JOIN Production.ProductSubcategory PSC ON P.ProductSubcategoryID = PSC.ProductSubcategoryID
    LEFT JOIN Production.ProductCategory PC ON PSC.ProductCategoryID = PC.ProductCategoryID
    WHERE P.ListPrice > 0
)
SELECT 
    ProductID,
    NomeProduto,
    Categoria,
    Subcategoria,
    FORMAT(ListPrice, 'C', 'pt-BR') AS PrecoAtual,
    FORMAT(StandardCost, 'C', 'pt-BR') AS CustoAtual,
    
    -- Preço do produto anterior na mesma categoria
    LAG(ListPrice, 1) OVER (
        PARTITION BY Categoria 
        ORDER BY ListPrice
    ) AS PrecoAnterior,
    
    -- Preço do próximo produto na mesma categoria
    LEAD(ListPrice, 1) OVER (
        PARTITION BY Categoria 
        ORDER BY ListPrice
    ) AS ProximoPreco,
    
    -- Percentual relativo com preço anterior
    CASE 
        WHEN LAG(ListPrice, 1) OVER (PARTITION BY Categoria ORDER BY ListPrice) > 0
        THEN ROUND(
            ((ListPrice - LAG(ListPrice, 1) OVER (PARTITION BY Categoria ORDER BY ListPrice)) * 100.0) / 
            LAG(ListPrice, 1) OVER (PARTITION BY Categoria ORDER BY ListPrice), 2
        )
        ELSE NULL
    END AS PercentualComAnterior,
    
    -- Percentual relativo com próximo preço
    CASE 
        WHEN LEAD(ListPrice, 1) OVER (PARTITION BY Categoria ORDER BY ListPrice) > 0
        THEN ROUND(
            ((LEAD(ListPrice, 1) OVER (PARTITION BY Categoria ORDER BY ListPrice) - ListPrice) * 100.0) / 
            ListPrice, 2
        )
        ELSE NULL
    END AS PercentualComProximo,
    
    -- Posição do preço na categoria
    ROW_NUMBER() OVER (
        PARTITION BY Categoria 
        ORDER BY ListPrice
    ) AS PosicaoPreco,
    
    -- Primeiro e último preço da categoria
    FIRST_VALUE(ListPrice) OVER (
        PARTITION BY Categoria 
        ORDER BY ListPrice
        ROWS UNBOUNDED PRECEDING
    ) AS MenorPrecoDaCategoria,
    
    LAST_VALUE(ListPrice) OVER (
        PARTITION BY Categoria 
        ORDER BY ListPrice
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS MaiorPrecoDaCategoria
FROM ProdutosComPrecos
WHERE Categoria IS NOT NULL
ORDER BY Categoria, ListPrice;

-- =============================================
-- EXEMPLO 5: Análise de Gaps em Séries Temporais
-- =============================================
-- Identificação de lacunas em dados temporais

WITH VendasDiarias AS (
    SELECT 
        CAST(OrderDate AS DATE) AS DataVenda,
        COUNT(*) AS QtdePedidos,
        SUM(TotalDue) AS TotalVendas
    FROM Sales.SalesOrderHeader
    WHERE OrderDate >= '2014-06-01' AND OrderDate < '2014-07-01'
    GROUP BY CAST(OrderDate AS DATE)
)
SELECT 
    DataVenda,
    QtdePedidos,
    FORMAT(TotalVendas, 'C', 'pt-BR') AS TotalVendas,
    
    -- Data da venda anterior
    LAG(DataVenda, 1) OVER (ORDER BY DataVenda) AS DataVendaAnterior,
    
    -- Dias entre vendas
    DATEDIFF(DAY, 
        LAG(DataVenda, 1) OVER (ORDER BY DataVenda), 
        DataVenda
    ) AS DiasEntreDatas,
    
    -- Identificação de gaps (mais de 1 dia)
    CASE 
        WHEN DATEDIFF(DAY, LAG(DataVenda, 1) OVER (ORDER BY DataVenda), DataVenda) > 1
        THEN '⚠️ Gap detectado'
        WHEN DATEDIFF(DAY, LAG(DataVenda, 1) OVER (ORDER BY DataVenda), DataVenda) = 1
        THEN '✅ Sequencial'
        ELSE '🆕 Primeiro registro'
    END AS StatusSequencia,
    
    -- Próxima data com vendas
    LEAD(DataVenda, 1) OVER (ORDER BY DataVenda) AS ProximaDataVenda
FROM VendasDiarias
ORDER BY DataVenda;

-- =============================================
-- EXERCÍCIOS PRÁTICOS
-- =============================================

-- Exercício 1: Crie uma análise de crescimento trimestral
-- usando LAG para comparar com trimestre anterior
-- TODO: Implemente aqui

-- Exercício 2: Use FIRST_VALUE e LAST_VALUE para analisar
-- a performance de vendedores no primeiro e último mês do ano
-- TODO: Implemente aqui

-- Exercício 3: Implemente uma análise de sazonalidade
-- comparando cada mês com o mesmo mês dos anos anteriores
-- TODO: Implemente aqui