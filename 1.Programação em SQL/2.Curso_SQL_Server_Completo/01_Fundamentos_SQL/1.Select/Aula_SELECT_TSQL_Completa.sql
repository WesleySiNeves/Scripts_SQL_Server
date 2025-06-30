/*
=============================================
AULA COMPLETA: SELECT EM T-SQL
=============================================
Autor: Wesley Neves
Data de Criação: 2024-12-19
Descrição: Aula completa sobre comando SELECT em T-SQL
           Desde conceitos básicos até técnicas avançadas
           Usando o banco de dados EcommerceDB

Pré-requisito: Execute o script 2.CriacaoTabelas.sql antes desta aula

Tópicos Abordados:
1. Sintaxe Básica do SELECT
2. Filtragem com WHERE
3. Ordenação com ORDER BY
4. Agrupamento com GROUP BY
5. Funções de Agregação
6. Subconsultas
7. JOINs
8. Funções de Janela (Window Functions)
9. CTEs (Common Table Expressions)
10. Casos Práticos e Exercícios
=============================================
*/

-- Conectar ao banco de dados do curso
USE EcommerceDB;
GO

-- ═══════════════════════════════════════════════════════════════
-- 1. SINTAXE BÁSICA DO SELECT
-- ═══════════════════════════════════════════════════════════════

-- Estrutura básica do SELECT
/*
SELECT [DISTINCT] [TOP (n)] lista_de_colunas
FROM nome_da_tabela
[WHERE condições]
[GROUP BY colunas_agrupamento]
[HAVING condições_grupo]
[ORDER BY colunas_ordenacao]
*/

-- Exemplo 1: Seleção simples - Visualizar todos os produtos
SELECT * FROM Produtos;

-- Exemplo 2: Seleção de colunas específicas
SELECT NomeProduto, PrecoVenda, EstoqueAtual 
FROM Produtos;

-- Exemplo 3: Usando alias para colunas
SELECT 
    NomeProduto AS Produto,
    PrecoVenda AS Preco,
    EstoqueAtual AS Estoque
FROM Produtos;

-- Exemplo 4: Usando TOP para limitar resultados
SELECT TOP 5 NomeProduto, PrecoVenda 
FROM Produtos;

-- Exemplo 5: Usando DISTINCT para valores únicos
SELECT DISTINCT StatusVenda 
FROM Vendas;

-- ═══════════════════════════════════════════════════════════════
-- 2. FILTRAGEM COM WHERE
-- ═══════════════════════════════════════════════════════════════

-- Operadores de comparação: =, <>, !=, <, >, <=, >=
SELECT NomeProduto, PrecoVenda 
FROM Produtos 
WHERE PrecoVenda > 500;

-- Operadores lógicos: AND, OR, NOT
SELECT NomeProduto, CategoriaID, PrecoVenda 
FROM Produtos 
WHERE CategoriaID = 1 AND PrecoVenda > 1000;

-- Operador IN para múltiplos valores
SELECT NomeCompleto, TipoCliente 
FROM Clientes 
WHERE TipoCliente IN ('F', 'J');

-- Operador BETWEEN para intervalos
SELECT NomeProduto, PrecoVenda 
FROM Produtos 
WHERE PrecoVenda BETWEEN 50 AND 500;

-- Operador LIKE para busca de padrões
SELECT NomeProduto 
FROM Produtos 
WHERE NomeProduto LIKE 'Smartphone%';  -- Produtos que começam com 'Smartphone'

SELECT NomeCompleto 
FROM Clientes 
WHERE NomeCompleto LIKE '%Silva%'; -- Clientes que contêm 'Silva' no nome

SELECT NomeProduto 
FROM Produtos 
WHERE NomeProduto LIKE '%Nike%';  -- Produtos que contêm 'Nike'

-- Verificação de valores NULL
SELECT NomeCompleto, CNPJ 
FROM Clientes 
WHERE CNPJ IS NULL;

SELECT NomeCompleto, Email 
FROM Clientes 
WHERE Email IS NOT NULL;

-- ═══════════════════════════════════════════════════════════════
-- 3. ORDENAÇÃO COM ORDER BY
-- ═══════════════════════════════════════════════════════════════

-- Ordenação crescente (padrão)
SELECT NomeProduto, PrecoVenda 
FROM Produtos 
ORDER BY PrecoVenda;

-- Ordenação decrescente
SELECT NomeProduto, PrecoVenda 
FROM Produtos 
ORDER BY PrecoVenda DESC;

-- Ordenação por múltiplas colunas
SELECT NomeProduto, CategoriaID, PrecoVenda 
FROM Produtos 
ORDER BY CategoriaID ASC, PrecoVenda DESC;

-- Ordenação por posição da coluna
SELECT NomeProduto, CategoriaID, PrecoVenda 
FROM Produtos 
ORDER BY 2, 3 DESC; -- Ordena pela 2ª coluna (CategoriaID) e depois pela 3ª (PrecoVenda)

-- ═══════════════════════════════════════════════════════════════
-- 4. FUNÇÕES DE AGREGAÇÃO
-- ═══════════════════════════════════════════════════════════════

-- COUNT - Conta registros
SELECT COUNT(*) AS TotalProdutos 
FROM Produtos;

SELECT COUNT(ImagemURL) AS ProdutosComImagem 
FROM Produtos; -- Não conta valores NULL

-- SUM - Soma valores
SELECT SUM(EstoqueAtual) AS TotalEstoque 
FROM Produtos;

-- AVG - Média dos valores
SELECT AVG(PrecoVenda) AS PrecoMedio 
FROM Produtos;

-- MIN e MAX - Valores mínimo e máximo
SELECT 
    MIN(PrecoVenda) AS MenorPreco,
    MAX(PrecoVenda) AS MaiorPreco
FROM Produtos;

-- ═══════════════════════════════════════════════════════════════
-- 5. AGRUPAMENTO COM GROUP BY
-- ═══════════════════════════════════════════════════════════════

-- Agrupamento básico
SELECT 
    CategoriaID,
    COUNT(*) AS QuantidadeProdutos
FROM Produtos 
GROUP BY CategoriaID;

-- Múltiplas funções de agregação
SELECT 
    CategoriaID,
    COUNT(*) AS Quantidade,
    AVG(PrecoVenda) AS PrecoMedio,
    MIN(PrecoVenda) AS MenorPreco,
    MAX(PrecoVenda) AS MaiorPreco
FROM Produtos 
GROUP BY CategoriaID;

-- Agrupamento por múltiplas colunas
SELECT 
    CategoriaID,
    FornecedorID,
    COUNT(*) AS Quantidade,
    AVG(PrecoVenda) AS PrecoMedio
FROM Produtos 
GROUP BY CategoriaID, FornecedorID;

-- ═══════════════════════════════════════════════════════════════
-- 6. FILTRAGEM DE GRUPOS COM HAVING
-- ═══════════════════════════════════════════════════════════════

-- HAVING é usado para filtrar grupos (após GROUP BY)
SELECT 
    CategoriaID,
    COUNT(*) AS QuantidadeProdutos,
    AVG(PrecoVenda) AS PrecoMedio
FROM Produtos 
GROUP BY CategoriaID
HAVING COUNT(*) > 1; -- Apenas categorias com mais de 1 produto

-- Combinando WHERE e HAVING
SELECT 
    CategoriaID,
    COUNT(*) AS QuantidadeProdutos,
    AVG(PrecoVenda) AS PrecoMedio
FROM Produtos 
WHERE PrecoVenda > 100  -- Filtra antes do agrupamento
GROUP BY CategoriaID
HAVING AVG(PrecoVenda) > 500; -- Filtra após o agrupamento

-- ═══════════════════════════════════════════════════════════════
-- 7. SUBCONSULTAS (SUBQUERIES)
-- ═══════════════════════════════════════════════════════════════

-- Subconsulta no WHERE
SELECT NomeProduto, PrecoVenda 
FROM Produtos 
WHERE PrecoVenda > (SELECT AVG(PrecoVenda) FROM Produtos);

-- Subconsulta com IN
SELECT NomeProduto, CategoriaID 
FROM Produtos 
WHERE CategoriaID IN (
    SELECT CategoriaID 
    FROM Categorias 
    WHERE NomeCategoria LIKE '%Eletrônicos%'
);

-- Subconsulta correlacionada
SELECT 
    p1.NomeProduto,
    p1.CategoriaID,
    p1.PrecoVenda
FROM Produtos p1
WHERE p1.PrecoVenda > (
    SELECT AVG(p2.PrecoVenda)
    FROM Produtos p2
    WHERE p2.CategoriaID = p1.CategoriaID
);

-- Subconsulta no SELECT
SELECT 
    NomeProduto,
    PrecoVenda,
    (SELECT AVG(PrecoVenda) FROM Produtos) AS PrecoMedioGeral,
    PrecoVenda - (SELECT AVG(PrecoVenda) FROM Produtos) AS DiferencaMedia
FROM Produtos;

-- ═══════════════════════════════════════════════════════════════
-- 8. JOINS - RELACIONANDO TABELAS
-- ═══════════════════════════════════════════════════════════════

-- INNER JOIN - Retorna apenas registros que têm correspondência em ambas as tabelas
SELECT 
    p.NomeProduto,
    p.PrecoVenda,
    c.NomeCategoria,
    f.NomeFornecedor
FROM Produtos p
INNER JOIN Categorias c ON p.CategoriaID = c.CategoriaID
INNER JOIN Fornecedores f ON p.FornecedorID = f.FornecedorID;

-- LEFT JOIN - Retorna todos os registros da tabela à esquerda
SELECT 
    p.NomeProduto,
    p.PrecoVenda,
    c.NomeCategoria
FROM Produtos p
LEFT JOIN Categorias c ON p.CategoriaID = c.CategoriaID;

-- RIGHT JOIN - Retorna todos os registros da tabela à direita
SELECT 
    p.NomeProduto,
    c.NomeCategoria
FROM Produtos p
RIGHT JOIN Categorias c ON p.CategoriaID = c.CategoriaID;

-- FULL OUTER JOIN - Retorna todos os registros de ambas as tabelas
SELECT 
    p.NomeProduto,
    c.NomeCategoria
FROM Produtos p
FULL OUTER JOIN Categorias c ON p.CategoriaID = c.CategoriaID;

-- JOIN com múltiplas tabelas
SELECT 
    p.NomeProduto,
    c.NomeCategoria,
    f.NomeFornecedor,
    p.PrecoVenda
FROM Produtos p
INNER JOIN Categorias c ON p.CategoriaID = c.CategoriaID
INNER JOIN Fornecedores f ON p.FornecedorID = f.FornecedorID;

-- ═══════════════════════════════════════════════════════════════
-- 9. FUNÇÕES DE JANELA (WINDOW FUNCTIONS)
-- ═══════════════════════════════════════════════════════════════

-- ROW_NUMBER() - Numera as linhas
SELECT 
    NomeProduto,
    CategoriaID,
    PrecoVenda,
    ROW_NUMBER() OVER (ORDER BY PrecoVenda DESC) AS Ranking
FROM Produtos;

-- RANK() e DENSE_RANK()
SELECT 
    NomeProduto,
    CategoriaID,
    PrecoVenda,
    RANK() OVER (ORDER BY PrecoVenda DESC) AS Rank_Normal,
    DENSE_RANK() OVER (ORDER BY PrecoVenda DESC) AS Rank_Denso
FROM Produtos;

-- Particionamento com PARTITION BY
SELECT 
    NomeProduto,
    CategoriaID,
    PrecoVenda,
    ROW_NUMBER() OVER (PARTITION BY CategoriaID ORDER BY PrecoVenda DESC) AS RankingCategoria
FROM Produtos;

-- Funções de agregação como Window Functions
SELECT 
    NomeProduto,
    CategoriaID,
    PrecoVenda,
    AVG(PrecoVenda) OVER (PARTITION BY CategoriaID) AS PrecoMedioCategoria,
    COUNT(*) OVER (PARTITION BY CategoriaID) AS TotalProdutosCategoria
FROM Produtos;

-- LAG e LEAD - Acessar valores de linhas anteriores/posteriores
SELECT 
    NomeProduto,
    CategoriaID,
    PrecoVenda,
    LAG(PrecoVenda, 1) OVER (ORDER BY PrecoVenda) AS PrecoAnterior,
    LEAD(PrecoVenda, 1) OVER (ORDER BY PrecoVenda) AS ProximoPreco
FROM Produtos;

-- ═══════════════════════════════════════════════════════════════
-- 10. CTEs (COMMON TABLE EXPRESSIONS)
-- ═══════════════════════════════════════════════════════════════

-- CTE Simples
WITH ProdutosCaros AS (
    SELECT 
        NomeProduto,
        CategoriaID,
        PrecoVenda
    FROM Produtos
    WHERE PrecoVenda > 500
)
SELECT * FROM ProdutosCaros
ORDER BY PrecoVenda DESC;

-- CTE com múltiplas definições
WITH 
EstatisticasCategoria AS (
    SELECT 
        CategoriaID,
        COUNT(*) AS TotalProdutos,
        AVG(PrecoVenda) AS PrecoMedio
    FROM Produtos
    GROUP BY CategoriaID
),
CategoriasPopulares AS (
    SELECT CategoriaID
    FROM EstatisticasCategoria
    WHERE TotalProdutos > 1
)
SELECT 
    p.NomeProduto,
    p.CategoriaID,
    p.PrecoVenda,
    e.PrecoMedio
FROM Produtos p
INNER JOIN EstatisticasCategoria e ON p.CategoriaID = e.CategoriaID
INNER JOIN CategoriasPopulares cp ON p.CategoriaID = cp.CategoriaID;

-- CTE Recursiva (exemplo: sequência numérica)
WITH SequenciaNumerica AS (
    -- Âncora: valor inicial
    SELECT 1 AS Numero
    
    UNION ALL
    
    -- Parte recursiva: incrementa até 10
    SELECT Numero + 1
    FROM SequenciaNumerica
    WHERE Numero < 10
)
SELECT 
    Numero,
    'Produto ' + CAST(Numero AS VARCHAR(10)) AS NomeProdutoExemplo
FROM SequenciaNumerica
ORDER BY Numero;

-- ═══════════════════════════════════════════════════════════════
-- 11. FUNÇÕES ÚTEIS EM SELECT
-- ═══════════════════════════════════════════════════════════════

-- Funções de String
SELECT 
    Nome,
    UPPER(Nome) AS NomeMaiusculo,
    LOWER(Nome) AS NomeMinusculo,
    LEN(Nome) AS TamanhoNome,
    LEFT(Nome, 3) AS PrimeirasLetras,
    RIGHT(Nome, 3) AS UltimasLetras,
    SUBSTRING(Nome, 2, 3) AS SubString
FROM Funcionarios;

-- Funções de Data
SELECT 
    Nome,
    DataAdmissao,
    GETDATE() AS DataAtual,
    DATEDIFF(YEAR, DataAdmissao, GETDATE()) AS AnosEmpresa,
    DATEDIFF(DAY, DataAdmissao, GETDATE()) AS DiasEmpresa,
    DATEADD(YEAR, 1, DataAdmissao) AS AniversarioUmAno
FROM Funcionarios;

-- Funções Matemáticas
SELECT 
    Nome,
    Salario,
    ROUND(Salario * 1.1, 2) AS SalarioComAumento,
    CEILING(Salario / 1000.0) AS SalarioArredondadoCima,
    FLOOR(Salario / 1000.0) AS SalarioArredondadoBaixo,
    ABS(Salario - 5000) AS DiferencaAbsoluta
FROM Funcionarios;

-- Função CASE para lógica condicional
SELECT 
    NomeProduto,
    PrecoVenda,
    CASE 
        WHEN PrecoVenda < 100 THEN 'Barato'
        WHEN PrecoVenda BETWEEN 100 AND 500 THEN 'Médio'
        WHEN PrecoVenda > 500 THEN 'Caro'
        ELSE 'Não Definido'
    END AS FaixaPreco
FROM Produtos;

-- Função COALESCE para tratar valores NULL
SELECT 
    NomeProduto,
    COALESCE(ImagemURL, 'Sem imagem') AS ImagemTratada,
    COALESCE(Descricao, 'Descrição não disponível') AS DescricaoTratada
FROM Produtos;

-- ═══════════════════════════════════════════════════════════════
-- 12. UNION E UNION ALL
-- ═══════════════════════════════════════════════════════════════

-- UNION - Combina resultados removendo duplicatas
SELECT NomeProduto AS Nome, 'Produto' AS Tipo FROM Produtos
UNION
SELECT NomeCategoria, 'Categoria' AS Tipo FROM Categorias;

-- UNION ALL - Combina resultados mantendo duplicatas
SELECT NomeProduto AS Nome, 'Produto' AS Tipo FROM Produtos
UNION ALL
SELECT NomeFornecedor, 'Fornecedor' AS Tipo FROM Fornecedores;

-- ═══════════════════════════════════════════════════════════════
-- 13. TÉCNICAS AVANÇADAS
-- ═══════════════════════════════════════════════════════════════

-- PIVOT - Transformar linhas em colunas (exemplo com vendas por categoria)
SELECT *
FROM (
    SELECT 
        YEAR(v.DataVenda) AS Ano,
        c.NomeCategoria,
        iv.Quantidade
    FROM Vendas v
    INNER JOIN ItensVenda iv ON v.VendaID = iv.VendaID
    INNER JOIN Produtos p ON iv.ProdutoID = p.ProdutoID
    INNER JOIN Categorias c ON p.CategoriaID = c.CategoriaID
) AS SourceTable
PIVOT (
    SUM(Quantidade)
    FOR NomeCategoria IN ([Eletrônicos], [Roupas], [Casa])
) AS PivotTable;

-- UNPIVOT - Transformar colunas em linhas
SELECT Departamento, Trimestre, Vendas
FROM (
    SELECT Departamento, Q1, Q2, Q3, Q4
    FROM VendasTrimestre
) AS SourceTable
UNPIVOT (
    Vendas FOR Trimestre IN (Q1, Q2, Q3, Q4)
) AS UnpivotTable;

-- CROSS APPLY e OUTER APPLY
SELECT 
    d.NomeDepartamento,
    top_func.Nome,
    top_func.Salario
FROM Departamentos d
CROSS APPLY (
    SELECT TOP 3 Nome, Salario
    FROM Funcionarios f
    WHERE f.DepartamentoID = d.DepartamentoID
    ORDER BY Salario DESC
) AS top_func;

-- ═══════════════════════════════════════════════════════════════
-- 13. EXERCÍCIOS PRÁTICOS
-- ═══════════════════════════════════════════════════════════════

-- Exercício 1: Encontre os 5 produtos mais caros
SELECT TOP 5 NomeProduto, PrecoVenda
FROM Produtos
ORDER BY PrecoVenda DESC;

-- Exercício 2: Calcule o preço médio por categoria, apenas para categorias com mais de 1 produto
SELECT 
    CategoriaID,
    COUNT(*) AS TotalProdutos,
    AVG(PrecoVenda) AS PrecoMedio
FROM Produtos
GROUP BY CategoriaID
HAVING COUNT(*) > 1;

-- Exercício 3: Liste produtos que custam acima da média de sua categoria
SELECT 
    p1.NomeProduto,
    p1.CategoriaID,
    p1.PrecoVenda,
    (
        SELECT AVG(p2.PrecoVenda)
        FROM Produtos p2
        WHERE p2.CategoriaID = p1.CategoriaID
    ) AS MediaCategoria
FROM Produtos p1
WHERE p1.PrecoVenda > (
    SELECT AVG(p2.PrecoVenda)
    FROM Produtos p2
    WHERE p2.CategoriaID = p1.CategoriaID
);

-- Exercício 4: Ranking de produtos por preço dentro de cada categoria
SELECT 
    NomeProduto,
    CategoriaID,
    PrecoVenda,
    RANK() OVER (PARTITION BY CategoriaID ORDER BY PrecoVenda DESC) AS RankingCategoria
FROM Produtos;

-- Exercício 5: Produtos com baixo estoque (menos de 10 unidades)
SELECT 
    NomeProduto,
    EstoqueAtual,
    CASE 
        WHEN EstoqueAtual = 0 THEN 'Sem Estoque'
        WHEN EstoqueAtual < 5 THEN 'Estoque Crítico'
        WHEN EstoqueAtual < 10 THEN 'Estoque Baixo'
        ELSE 'Estoque OK'
    END AS StatusEstoque
FROM Produtos
WHERE EstoqueAtual < 10
ORDER BY EstoqueAtual ASC;

-- ═══════════════════════════════════════════════════════════════
-- 14. DICAS DE PERFORMANCE
-- ═══════════════════════════════════════════════════════════════

/*
DICAS IMPORTANTES PARA PERFORMANCE:

1. Use índices apropriados nas colunas do WHERE e JOIN
2. Evite SELECT * em produção - especifique apenas as colunas necessárias
3. Use EXISTS ao invés de IN para subconsultas quando possível
4. Prefira JOINs a subconsultas correlacionadas quando possível
5. Use UNION ALL ao invés de UNION quando não precisar eliminar duplicatas
6. Cuidado com funções em colunas do WHERE - podem impedir uso de índices
7. Use TOP ou OFFSET/FETCH para paginação
8. Considere usar CTEs para melhorar legibilidade de queries complexas
9. Monitore planos de execução para identificar gargalos
10. Use hints apenas quando necessário e com conhecimento
*/

-- ❌ EVITE: SELECT *
-- SELECT * FROM Produtos;

-- ✅ PREFIRA: Especificar colunas
-- SELECT NomeProduto, PrecoVenda FROM Produtos;

-- ❌ EVITE: Funções em WHERE
-- SELECT * FROM Vendas WHERE YEAR(DataVenda) = 2024;

-- ✅ PREFIRA: Filtros diretos
-- SELECT * FROM Vendas WHERE DataVenda >= '2024-01-01' AND DataVenda < '2025-01-01';

-- ❌ EVITE: OR em grandes volumes
-- SELECT * FROM Produtos WHERE CategoriaID = 1 OR CategoriaID = 2;

-- ✅ PREFIRA: IN
-- SELECT * FROM Produtos WHERE CategoriaID IN (1, 2);

-- ✅ USE: LIMIT/TOP para testes
-- SELECT TOP 100 * FROM Produtos;

-- ✅ USE: Índices apropriados (já criados no script de criação)
-- Os índices já estão criados no script 2.CriacaoTabelas.sql
-- Exemplo: IX_Produtos_Categoria, IX_Produtos_Preco, etc.

-- Exemplo de paginação eficiente
SELECT NomeProduto, PrecoVenda
FROM Produtos
ORDER BY PrecoVenda DESC
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY; -- Pula 10 registros e pega os próximos 5

-- Exemplo usando EXISTS (mais eficiente que IN em muitos casos)
SELECT NomeProduto, CategoriaID
FROM Produtos p
WHERE EXISTS (
    SELECT 1 
    FROM ItensVenda iv 
    WHERE iv.ProdutoID = p.ProdutoID
);

-- ═══════════════════════════════════════════════════════════════
-- 15. CONCLUSÃO
-- ═══════════════════════════════════════════════════════════════

/*
Esta aula cobriu os principais aspectos do comando SELECT em T-SQL:

✅ Sintaxe básica e seleção de dados
✅ Filtragem e ordenação
✅ Funções de agregação e agrupamento
✅ Subconsultas e JOINs
✅ Window Functions e CTEs
✅ Funções úteis e técnicas avançadas
✅ Exercícios práticos
✅ Dicas de performance

PRÓXIMOS PASSOS:
- Pratique com dados reais
- Estude planos de execução
- Aprenda sobre índices
- Explore stored procedures e functions
- Aprofunde-se em Window Functions

Lembre-se: A prática leva à perfeição!
*/

-- ═══════════════════════════════════════════════════════════════
-- FIM DA AULA
-- ═══════════════════════════════════════════════════════════════