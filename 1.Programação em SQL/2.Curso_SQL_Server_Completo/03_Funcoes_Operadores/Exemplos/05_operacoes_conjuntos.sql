-- =====================================================
-- CURSO SQL SERVER - MÓDULO 03: FUNÇÕES E OPERADORES
-- Arquivo: 05_operacoes_conjuntos.sql
-- Tópico: Operações de Conjuntos (Set Operations)
-- =====================================================

-- ÍNDICE:
-- 1. UNION e UNION ALL
-- 2. INTERSECT
-- 3. EXCEPT
-- 4. Comparação com JOINs
-- 5. Casos Práticos
-- 6. Exercícios Práticos

-- =====================================================
-- PREPARAÇÃO: Criando tabelas de exemplo
-- =====================================================

IF OBJECT_ID('TEMPDB..#Vendas2023') IS NOT NULL DROP TABLE #Vendas2023;
IF OBJECT_ID('TEMPDB..#Vendas2024') IS NOT NULL DROP TABLE #Vendas2024;
IF OBJECT_ID('TEMPDB..#Produtos') IS NOT NULL DROP TABLE #Produtos;
IF OBJECT_ID('TEMPDB..#Clientes') IS NOT NULL DROP TABLE #Clientes;

CREATE TABLE #Vendas2023 (
    IdVenda INT,
    IdCliente INT,
    IdProduto INT,
    Quantidade INT,
    Valor DECIMAL(10,2)
);

CREATE TABLE #Vendas2024 (
    IdVenda INT,
    IdCliente INT,
    IdProduto INT,
    Quantidade INT,
    Valor DECIMAL(10,2)
);

CREATE TABLE #Produtos (
    IdProduto INT,
    Nome VARCHAR(50),
    Categoria VARCHAR(30)
);

CREATE TABLE #Clientes (
    IdCliente INT,
    Nome VARCHAR(50),
    Cidade VARCHAR(30)
);

-- Inserindo dados de exemplo
INSERT INTO #Produtos VALUES
(1, 'Notebook Dell', 'Informática'),
(2, 'Mouse Logitech', 'Informática'),
(3, 'Teclado Mecânico', 'Informática'),
(4, 'Monitor 24"', 'Informática'),
(5, 'Cadeira Gamer', 'Móveis'),
(6, 'Mesa de Escritório', 'Móveis'),
(7, 'Smartphone Samsung', 'Eletrônicos'),
(8, 'Tablet iPad', 'Eletrônicos');

INSERT INTO #Clientes VALUES
(1, 'João Silva', 'São Paulo'),
(2, 'Maria Santos', 'Rio de Janeiro'),
(3, 'Pedro Oliveira', 'Belo Horizonte'),
(4, 'Ana Costa', 'São Paulo'),
(5, 'Carlos Ferreira', 'Salvador'),
(6, 'Lucia Almeida', 'Brasília');

INSERT INTO #Vendas2023 VALUES
(1, 1, 1, 1, 2500.00),
(2, 1, 2, 2, 150.00),
(3, 2, 3, 1, 300.00),
(4, 3, 4, 1, 800.00),
(5, 4, 5, 1, 1200.00),
(6, 2, 6, 1, 600.00),
(7, 5, 7, 1, 1500.00);

INSERT INTO #Vendas2024 VALUES
(8, 1, 1, 1, 2600.00),  -- João comprou notebook novamente
(9, 2, 2, 3, 160.00),   -- Maria comprou mais mouses
(10, 6, 3, 1, 320.00),  -- Lucia (nova cliente) comprou teclado
(11, 3, 8, 1, 2000.00), -- Pedro comprou tablet
(12, 4, 5, 2, 1300.00), -- Ana comprou mais cadeiras
(13, 1, 7, 1, 1600.00), -- João comprou smartphone
(14, 5, 4, 2, 850.00);  -- Carlos comprou monitores

-- =====================================================
-- 1. UNION e UNION ALL
-- =====================================================

-- Exemplo 1: UNION - Remove duplicatas
PRINT '=== UNION - Clientes que compraram em 2023 OU 2024 (sem duplicatas) ===';
SELECT DISTINCT V.IdCliente, C.Nome
FROM #Vendas2023 V
INNER JOIN #Clientes C ON V.IdCliente = C.IdCliente

UNION

SELECT DISTINCT V.IdCliente, C.Nome
FROM #Vendas2024 V
INNER JOIN #Clientes C ON V.IdCliente = C.IdCliente
ORDER BY IdCliente;

-- Exemplo 2: UNION ALL - Mantém duplicatas
PRINT '=== UNION ALL - Todas as vendas de ambos os anos (com duplicatas) ===';
SELECT 'Vendas 2023' AS Ano, IdVenda, IdCliente, IdProduto, Valor
FROM #Vendas2023

UNION ALL

SELECT 'Vendas 2024' AS Ano, IdVenda, IdCliente, IdProduto, Valor
FROM #Vendas2024
ORDER BY Ano, IdVenda;

-- Exemplo 3: UNION com diferentes estruturas (colunas compatíveis)
PRINT '=== UNION - Resumo de vendas por ano ===';
SELECT 2023 AS Ano, 
       COUNT(*) AS TotalVendas, 
       SUM(Valor) AS TotalFaturamento,
       AVG(Valor) AS TicketMedio
FROM #Vendas2023

UNION ALL

SELECT 2024 AS Ano, 
       COUNT(*) AS TotalVendas, 
       SUM(Valor) AS TotalFaturamento,
       AVG(Valor) AS TicketMedio
FROM #Vendas2024
ORDER BY Ano;

-- Exemplo 4: UNION com subconsultas
PRINT '=== UNION - Top 3 produtos mais vendidos por ano ===';
SELECT '2023' AS Ano, P.Nome, SUM(V.Quantidade) AS TotalVendido
FROM #Vendas2023 V
INNER JOIN #Produtos P ON V.IdProduto = P.IdProduto
GROUP BY P.Nome

UNION ALL

SELECT '2024' AS Ano, P.Nome, SUM(V.Quantidade) AS TotalVendido
FROM #Vendas2024 V
INNER JOIN #Produtos P ON V.IdProduto = P.IdProduto
GROUP BY P.Nome
ORDER BY Ano, TotalVendido DESC;

-- =====================================================
-- 2. INTERSECT
-- =====================================================

-- Exemplo 1: INTERSECT - Clientes que compraram em AMBOS os anos
PRINT '=== INTERSECT - Clientes que compraram em 2023 E 2024 ===';
SELECT V.IdCliente, C.Nome
FROM #Vendas2023 V
INNER JOIN #Clientes C ON V.IdCliente = C.IdCliente

INTERSECT

SELECT V.IdCliente, C.Nome
FROM #Vendas2024 V
INNER JOIN #Clientes C ON V.IdCliente = C.IdCliente;

-- Exemplo 2: INTERSECT - Produtos vendidos em ambos os anos
PRINT '=== INTERSECT - Produtos vendidos em ambos os anos ===';
SELECT V.IdProduto, P.Nome
FROM #Vendas2023 V
INNER JOIN #Produtos P ON V.IdProduto = P.IdProduto

INTERSECT

SELECT V.IdProduto, P.Nome
FROM #Vendas2024 V
INNER JOIN #Produtos P ON V.IdProduto = P.IdProduto;

-- Exemplo 3: Comparação INTERSECT vs INNER JOIN
PRINT '=== Comparação: INTERSECT vs INNER JOIN ===';

-- Com INTERSECT
SELECT 'INTERSECT' AS Metodo, COUNT(*) AS Registros
FROM (
    SELECT IdCliente FROM #Vendas2023
    INTERSECT
    SELECT IdCliente FROM #Vendas2024
) AS Resultado

UNION ALL

-- Com INNER JOIN
SELECT 'INNER JOIN' AS Metodo, COUNT(DISTINCT V1.IdCliente) AS Registros
FROM #Vendas2023 V1
INNER JOIN #Vendas2024 V2 ON V1.IdCliente = V2.IdCliente;

-- =====================================================
-- 3. EXCEPT
-- =====================================================

-- Exemplo 1: EXCEPT - Clientes que compraram apenas em 2023
PRINT '=== EXCEPT - Clientes que compraram APENAS em 2023 ===';
SELECT V.IdCliente, C.Nome
FROM #Vendas2023 V
INNER JOIN #Clientes C ON V.IdCliente = C.IdCliente

EXCEPT

SELECT V.IdCliente, C.Nome
FROM #Vendas2024 V
INNER JOIN #Clientes C ON V.IdCliente = C.IdCliente;

-- Exemplo 2: EXCEPT - Produtos vendidos apenas em 2024
PRINT '=== EXCEPT - Produtos vendidos APENAS em 2024 ===';
SELECT V.IdProduto, P.Nome
FROM #Vendas2024 V
INNER JOIN #Produtos P ON V.IdProduto = P.IdProduto

EXCEPT

SELECT V.IdProduto, P.Nome
FROM #Vendas2023 V
INNER JOIN #Produtos P ON V.IdProduto = P.IdProduto;

-- Exemplo 3: EXCEPT com múltiplas colunas
PRINT '=== EXCEPT - Combinações Cliente-Produto únicas de 2023 ===';
SELECT V.IdCliente, V.IdProduto, C.Nome AS Cliente, P.Nome AS Produto
FROM #Vendas2023 V
INNER JOIN #Clientes C ON V.IdCliente = C.IdCliente
INNER JOIN #Produtos P ON V.IdProduto = P.IdProduto

EXCEPT

SELECT V.IdCliente, V.IdProduto, C.Nome AS Cliente, P.Nome AS Produto
FROM #Vendas2024 V
INNER JOIN #Clientes C ON V.IdCliente = C.IdCliente
INNER JOIN #Produtos P ON V.IdProduto = P.IdProduto;

-- Exemplo 4: Caso prático do arquivo original - Semi-joins com EXCEPT
PRINT '=== Exemplo do arquivo original - Semi-joins com EXCEPT ===';

-- Simulando a estrutura do exemplo original
IF OBJECT_ID('TEMPDB..#Liquidacoes') IS NOT NULL DROP TABLE #Liquidacoes;

CREATE TABLE #Liquidacoes (
    IdEmpenho INT,
    IdLiquidacao INT,
    Valor DECIMAL(10,2),
    DataLiquidacao DATE,
    RestoAPagar BIT
);

INSERT INTO #Liquidacoes VALUES
(1, 101, 1000.00, '2015-01-15', 0),
(1, 102, 500.00, '2015-02-20', 0),
(2, 103, 2000.00, '2015-03-10', 0),
(2, 104, 1500.00, '2015-04-05', 1),
(3, 105, 800.00, '2015-05-12', 0),
(1, 106, 1000.00, '2015-06-18', 0); -- Duplicata do primeiro registro

-- Usando EXCEPT para encontrar registros únicos
SELECT ProjecaoA.IdEmpenho,
       ProjecaoA.IdLiquidacao,
       ProjecaoA.Valor
FROM (
    SELECT L.IdEmpenho,
           L.IdLiquidacao,
           L.Valor
    FROM #Liquidacoes AS L
    WHERE YEAR(L.DataLiquidacao) = 2015
      AND L.RestoAPagar = 0
    GROUP BY L.IdEmpenho, L.IdLiquidacao, L.Valor
) AS ProjecaoA

EXCEPT

-- Esta parte do EXCEPT não faz muito sentido no exemplo original
-- pois está comparando a mesma projeção consigo mesma
-- Vamos mostrar um uso mais prático:
SELECT L.IdEmpenho,
       L.IdLiquidacao,
       L.Valor
FROM #Liquidacoes AS L
WHERE L.RestoAPagar = 1; -- Excluir restos a pagar

DROP TABLE #Liquidacoes;

-- =====================================================
-- 4. COMPARAÇÃO COM JOINs
-- =====================================================

-- Exemplo 1: INTERSECT vs INNER JOIN
PRINT '=== Comparação de Performance: INTERSECT vs INNER JOIN ===';

-- Método 1: INTERSECT
SELECT 'INTERSECT' AS Metodo, IdCliente
FROM (
    SELECT IdCliente FROM #Vendas2023
    INTERSECT
    SELECT IdCliente FROM #Vendas2024
) AS Resultado;

-- Método 2: INNER JOIN com DISTINCT
SELECT DISTINCT 'INNER JOIN' AS Metodo, V1.IdCliente
FROM #Vendas2023 V1
INNER JOIN #Vendas2024 V2 ON V1.IdCliente = V2.IdCliente;

-- Método 3: EXISTS
SELECT DISTINCT 'EXISTS' AS Metodo, V1.IdCliente
FROM #Vendas2023 V1
WHERE EXISTS (
    SELECT 1 FROM #Vendas2024 V2 
    WHERE V2.IdCliente = V1.IdCliente
);

-- Exemplo 2: EXCEPT vs LEFT JOIN
PRINT '=== Comparação: EXCEPT vs LEFT JOIN ===';

-- Método 1: EXCEPT
SELECT 'EXCEPT' AS Metodo, IdCliente
FROM (
    SELECT IdCliente FROM #Vendas2023
    EXCEPT
    SELECT IdCliente FROM #Vendas2024
) AS Resultado;

-- Método 2: LEFT JOIN com IS NULL
SELECT DISTINCT 'LEFT JOIN' AS Metodo, V1.IdCliente
FROM #Vendas2023 V1
LEFT JOIN #Vendas2024 V2 ON V1.IdCliente = V2.IdCliente
WHERE V2.IdCliente IS NULL;

-- Método 3: NOT EXISTS
SELECT DISTINCT 'NOT EXISTS' AS Metodo, V1.IdCliente
FROM #Vendas2023 V1
WHERE NOT EXISTS (
    SELECT 1 FROM #Vendas2024 V2 
    WHERE V2.IdCliente = V1.IdCliente
);

-- =====================================================
-- 5. CASOS PRÁTICOS AVANÇADOS
-- =====================================================

-- Exemplo 1: Análise de churn de clientes
PRINT '=== Análise de Churn de Clientes ===';

WITH ClientesAnalise AS (
    SELECT 'Ativos em 2023' AS Status, COUNT(DISTINCT IdCliente) AS Quantidade
    FROM #Vendas2023
    
    UNION ALL
    
    SELECT 'Ativos em 2024' AS Status, COUNT(DISTINCT IdCliente) AS Quantidade
    FROM #Vendas2024
    
    UNION ALL
    
    SELECT 'Clientes Fiéis (ambos anos)' AS Status, COUNT(*) AS Quantidade
    FROM (
        SELECT IdCliente FROM #Vendas2023
        INTERSECT
        SELECT IdCliente FROM #Vendas2024
    ) AS Fieis
    
    UNION ALL
    
    SELECT 'Churn (saíram em 2024)' AS Status, COUNT(*) AS Quantidade
    FROM (
        SELECT IdCliente FROM #Vendas2023
        EXCEPT
        SELECT IdCliente FROM #Vendas2024
    ) AS Churn
    
    UNION ALL
    
    SELECT 'Novos (entraram em 2024)' AS Status, COUNT(*) AS Quantidade
    FROM (
        SELECT IdCliente FROM #Vendas2024
        EXCEPT
        SELECT IdCliente FROM #Vendas2023
    ) AS Novos
)
SELECT * FROM ClientesAnalise;

-- Exemplo 2: Análise de produtos
PRINT '=== Análise de Portfólio de Produtos ===';

SELECT 'Produtos vendidos apenas em 2023' AS Categoria,
       P.Nome,
       SUM(V.Quantidade) AS TotalVendido,
       SUM(V.Valor) AS TotalFaturamento
FROM #Vendas2023 V
INNER JOIN #Produtos P ON V.IdProduto = P.IdProduto
WHERE V.IdProduto IN (
    SELECT IdProduto FROM #Vendas2023
    EXCEPT
    SELECT IdProduto FROM #Vendas2024
)
GROUP BY P.Nome

UNION ALL

SELECT 'Produtos vendidos apenas em 2024' AS Categoria,
       P.Nome,
       SUM(V.Quantidade) AS TotalVendido,
       SUM(V.Valor) AS TotalFaturamento
FROM #Vendas2024 V
INNER JOIN #Produtos P ON V.IdProduto = P.IdProduto
WHERE V.IdProduto IN (
    SELECT IdProduto FROM #Vendas2024
    EXCEPT
    SELECT IdProduto FROM #Vendas2023
)
GROUP BY P.Nome

UNION ALL

SELECT 'Produtos vendidos em ambos os anos' AS Categoria,
       P.Nome,
       SUM(V2023.Quantidade + V2024.Quantidade) AS TotalVendido,
       SUM(V2023.Valor + V2024.Valor) AS TotalFaturamento
FROM (
    SELECT IdProduto FROM #Vendas2023
    INTERSECT
    SELECT IdProduto FROM #Vendas2024
) AS ProdutosComuns
INNER JOIN #Produtos P ON ProdutosComuns.IdProduto = P.IdProduto
INNER JOIN (
    SELECT IdProduto, SUM(Quantidade) AS Quantidade, SUM(Valor) AS Valor
    FROM #Vendas2023 GROUP BY IdProduto
) V2023 ON P.IdProduto = V2023.IdProduto
INNER JOIN (
    SELECT IdProduto, SUM(Quantidade) AS Quantidade, SUM(Valor) AS Valor
    FROM #Vendas2024 GROUP BY IdProduto
) V2024 ON P.IdProduto = V2024.IdProduto
GROUP BY P.Nome
ORDER BY Categoria, TotalFaturamento DESC;

-- =====================================================
-- 6. CONSIDERAÇÕES DE PERFORMANCE
-- =====================================================

-- Exemplo 1: Comparação de planos de execução
PRINT '=== Dicas de Performance ===';
PRINT '1. UNION ALL é mais rápido que UNION (não remove duplicatas)';
PRINT '2. Para grandes volumes, considere índices nas colunas usadas nas operações';
PRINT '3. INTERSECT e EXCEPT podem ser mais lentos que JOINs equivalentes';
PRINT '4. Use EXISTS/NOT EXISTS para melhor performance em alguns casos';

-- Exemplo de índices recomendados
/*
CREATE INDEX IX_Vendas2023_IdCliente ON #Vendas2023(IdCliente);
CREATE INDEX IX_Vendas2024_IdCliente ON #Vendas2024(IdCliente);
CREATE INDEX IX_Vendas2023_IdProduto ON #Vendas2023(IdProduto);
CREATE INDEX IX_Vendas2024_IdProduto ON #Vendas2024(IdProduto);
*/

-- Limpeza
DROP TABLE #Vendas2023, #Vendas2024, #Produtos, #Clientes;

-- =====================================================
-- 7. EXERCÍCIOS PRÁTICOS
-- =====================================================

/*
EXERCÍCIO 1:
Crie consultas usando UNION para combinar dados de vendas
de diferentes regiões, incluindo totalizações

EXERCÍCIO 2:
Use INTERSECT para encontrar produtos que foram vendidos
em todos os trimestres de um ano

EXERCÍCIO 3:
Implemente uma análise de churn usando EXCEPT para identificar
clientes que pararam de comprar

EXERCÍCIO 4:
Compare a performance entre operações de conjunto e JOINs
equivalentes em um dataset grande

EXERCÍCIO 5:
Crie um relatório que mostre:
- Produtos vendidos apenas online
- Produtos vendidos apenas em loja física
- Produtos vendidos em ambos os canais
*/

-- =====================================================
-- SOLUÇÕES DOS EXERCÍCIOS
-- =====================================================

-- SOLUÇÃO 1: UNION com totalizações
/*
SELECT Regiao, Produto, SUM(Quantidade) AS Total
FROM VendasSudeste
GROUP BY Regiao, Produto

UNION ALL

SELECT Regiao, Produto, SUM(Quantidade) AS Total
FROM VendasNordeste
GROUP BY Regiao, Produto

UNION ALL

SELECT 'TOTAL GERAL' AS Regiao, Produto, SUM(Total) AS Total
FROM (
    SELECT Produto, SUM(Quantidade) AS Total FROM VendasSudeste GROUP BY Produto
    UNION ALL
    SELECT Produto, SUM(Quantidade) AS Total FROM VendasNordeste GROUP BY Produto
) AS Consolidado
GROUP BY Produto
ORDER BY Regiao, Total DESC;
*/

-- SOLUÇÃO 2: INTERSECT para produtos em todos os trimestres
/*
SELECT IdProduto FROM VendasQ1
INTERSECT
SELECT IdProduto FROM VendasQ2
INTERSECT
SELECT IdProduto FROM VendasQ3
INTERSECT
SELECT IdProduto FROM VendasQ4;
*/

-- SOLUÇÃO 3: Análise de churn com EXCEPT
/*
SELECT C.Nome, C.Email, 'CHURN' AS Status
FROM (
    SELECT IdCliente FROM VendasAnoAnterior
    EXCEPT
    SELECT IdCliente FROM VendasAnoAtual
) AS ClientesChurn
INNER JOIN Clientes C ON ClientesChurn.IdCliente = C.IdCliente;
*/