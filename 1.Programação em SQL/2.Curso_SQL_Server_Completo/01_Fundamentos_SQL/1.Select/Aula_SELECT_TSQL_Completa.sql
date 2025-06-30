/*
=============================================
AULA COMPLETA: SELECT EM T-SQL
=============================================
Autor: Wesley Neves
Data de Criação: 2024-12-19
Descrição: Aula completa sobre comando SELECT em T-SQL
           Desde conceitos básicos até técnicas avançadas

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

-- Exemplo 1: Seleção simples
SELECT * FROM Funcionarios;

-- Exemplo 2: Seleção de colunas específicas
SELECT Nome, Sobrenome, Salario 
FROM Funcionarios;

-- Exemplo 3: Usando alias para colunas
SELECT 
    Nome AS PrimeiroNome,
    Sobrenome AS UltimoNome,
    Salario AS SalarioMensal
FROM Funcionarios;

-- Exemplo 4: Usando TOP para limitar resultados
SELECT TOP 10 Nome, Salario 
FROM Funcionarios;

-- Exemplo 5: Usando DISTINCT para valores únicos
SELECT DISTINCT Departamento 
FROM Funcionarios;

-- ═══════════════════════════════════════════════════════════════
-- 2. FILTRAGEM COM WHERE
-- ═══════════════════════════════════════════════════════════════

-- Operadores de comparação: =, <>, !=, <, >, <=, >=
SELECT Nome, Salario 
FROM Funcionarios 
WHERE Salario > 5000;

-- Operadores lógicos: AND, OR, NOT
SELECT Nome, Departamento, Salario 
FROM Funcionarios 
WHERE Departamento = 'TI' AND Salario > 4000;

-- Operador IN para múltiplos valores
SELECT Nome, Departamento 
FROM Funcionarios 
WHERE Departamento IN ('TI', 'Vendas', 'Marketing');

-- Operador BETWEEN para intervalos
SELECT Nome, Salario 
FROM Funcionarios 
WHERE Salario BETWEEN 3000 AND 7000;

-- Operador LIKE para busca de padrões
SELECT Nome 
FROM Funcionarios 
WHERE Nome LIKE 'João%';  -- Nomes que começam com 'João'

SELECT Nome 
FROM Funcionarios 
WHERE Nome LIKE '%Silva'; -- Nomes que terminam com 'Silva'

SELECT Nome 
FROM Funcionarios 
WHERE Nome LIKE '%Ana%';  -- Nomes que contêm 'Ana'

-- Verificação de valores NULL
SELECT Nome, Email 
FROM Funcionarios 
WHERE Email IS NULL;

SELECT Nome, Email 
FROM Funcionarios 
WHERE Email IS NOT NULL;

-- ═══════════════════════════════════════════════════════════════
-- 3. ORDENAÇÃO COM ORDER BY
-- ═══════════════════════════════════════════════════════════════

-- Ordenação crescente (padrão)
SELECT Nome, Salario 
FROM Funcionarios 
ORDER BY Salario;

-- Ordenação decrescente
SELECT Nome, Salario 
FROM Funcionarios 
ORDER BY Salario DESC;

-- Ordenação por múltiplas colunas
SELECT Nome, Departamento, Salario 
FROM Funcionarios 
ORDER BY Departamento ASC, Salario DESC;

-- Ordenação por posição da coluna
SELECT Nome, Departamento, Salario 
FROM Funcionarios 
ORDER BY 2, 3 DESC; -- Ordena pela 2ª coluna (Departamento) e depois pela 3ª (Salario)

-- ═══════════════════════════════════════════════════════════════
-- 4. FUNÇÕES DE AGREGAÇÃO
-- ═══════════════════════════════════════════════════════════════

-- COUNT - Conta registros
SELECT COUNT(*) AS TotalFuncionarios 
FROM Funcionarios;

SELECT COUNT(Email) AS FuncionariosComEmail 
FROM Funcionarios; -- Não conta valores NULL

-- SUM - Soma valores
SELECT SUM(Salario) AS TotalFolhaPagamento 
FROM Funcionarios;

-- AVG - Média dos valores
SELECT AVG(Salario) AS SalarioMedio 
FROM Funcionarios;

-- MIN e MAX - Valores mínimo e máximo
SELECT 
    MIN(Salario) AS MenorSalario,
    MAX(Salario) AS MaiorSalario
FROM Funcionarios;

-- ═══════════════════════════════════════════════════════════════
-- 5. AGRUPAMENTO COM GROUP BY
-- ═══════════════════════════════════════════════════════════════

-- Agrupamento básico
SELECT 
    Departamento,
    COUNT(*) AS QuantidadeFuncionarios
FROM Funcionarios 
GROUP BY Departamento;

-- Múltiplas funções de agregação
SELECT 
    Departamento,
    COUNT(*) AS Quantidade,
    AVG(Salario) AS SalarioMedio,
    MIN(Salario) AS MenorSalario,
    MAX(Salario) AS MaiorSalario
FROM Funcionarios 
GROUP BY Departamento;

-- Agrupamento por múltiplas colunas
SELECT 
    Departamento,
    Cargo,
    COUNT(*) AS Quantidade,
    AVG(Salario) AS SalarioMedio
FROM Funcionarios 
GROUP BY Departamento, Cargo;

-- ═══════════════════════════════════════════════════════════════
-- 6. FILTRAGEM DE GRUPOS COM HAVING
-- ═══════════════════════════════════════════════════════════════

-- HAVING é usado para filtrar grupos (após GROUP BY)
SELECT 
    Departamento,
    COUNT(*) AS QuantidadeFuncionarios,
    AVG(Salario) AS SalarioMedio
FROM Funcionarios 
GROUP BY Departamento
HAVING COUNT(*) > 5; -- Apenas departamentos com mais de 5 funcionários

-- Combinando WHERE e HAVING
SELECT 
    Departamento,
    COUNT(*) AS QuantidadeFuncionarios,
    AVG(Salario) AS SalarioMedio
FROM Funcionarios 
WHERE Salario > 3000  -- Filtra antes do agrupamento
GROUP BY Departamento
HAVING AVG(Salario) > 5000; -- Filtra após o agrupamento

-- ═══════════════════════════════════════════════════════════════
-- 7. SUBCONSULTAS (SUBQUERIES)
-- ═══════════════════════════════════════════════════════════════

-- Subconsulta no WHERE
SELECT Nome, Salario 
FROM Funcionarios 
WHERE Salario > (SELECT AVG(Salario) FROM Funcionarios);

-- Subconsulta com IN
SELECT Nome, Departamento 
FROM Funcionarios 
WHERE Departamento IN (
    SELECT Departamento 
    FROM Departamentos 
    WHERE Orcamento > 100000
);

-- Subconsulta correlacionada
SELECT 
    f1.Nome,
    f1.Departamento,
    f1.Salario
FROM Funcionarios f1
WHERE f1.Salario > (
    SELECT AVG(f2.Salario)
    FROM Funcionarios f2
    WHERE f2.Departamento = f1.Departamento
);

-- Subconsulta no SELECT
SELECT 
    Nome,
    Salario,
    (SELECT AVG(Salario) FROM Funcionarios) AS SalarioMedioGeral,
    Salario - (SELECT AVG(Salario) FROM Funcionarios) AS DiferencaMedia
FROM Funcionarios;

-- ═══════════════════════════════════════════════════════════════
-- 8. JOINS - RELACIONANDO TABELAS
-- ═══════════════════════════════════════════════════════════════

-- INNER JOIN - Retorna apenas registros que têm correspondência em ambas as tabelas
SELECT 
    f.Nome,
    f.Sobrenome,
    d.NomeDepartamento,
    f.Salario
FROM Funcionarios f
INNER JOIN Departamentos d ON f.DepartamentoID = d.DepartamentoID;

-- LEFT JOIN - Retorna todos os registros da tabela à esquerda
SELECT 
    f.Nome,
    f.Sobrenome,
    d.NomeDepartamento
FROM Funcionarios f
LEFT JOIN Departamentos d ON f.DepartamentoID = d.DepartamentoID;

-- RIGHT JOIN - Retorna todos os registros da tabela à direita
SELECT 
    f.Nome,
    d.NomeDepartamento
FROM Funcionarios f
RIGHT JOIN Departamentos d ON f.DepartamentoID = d.DepartamentoID;

-- FULL OUTER JOIN - Retorna todos os registros de ambas as tabelas
SELECT 
    f.Nome,
    d.NomeDepartamento
FROM Funcionarios f
FULL OUTER JOIN Departamentos d ON f.DepartamentoID = d.DepartamentoID;

-- JOIN com múltiplas tabelas
SELECT 
    f.Nome,
    d.NomeDepartamento,
    c.NomeCargo,
    f.Salario
FROM Funcionarios f
INNER JOIN Departamentos d ON f.DepartamentoID = d.DepartamentoID
INNER JOIN Cargos c ON f.CargoID = c.CargoID;

-- ═══════════════════════════════════════════════════════════════
-- 9. FUNÇÕES DE JANELA (WINDOW FUNCTIONS)
-- ═══════════════════════════════════════════════════════════════

-- ROW_NUMBER() - Numera as linhas
SELECT 
    Nome,
    Departamento,
    Salario,
    ROW_NUMBER() OVER (ORDER BY Salario DESC) AS Ranking
FROM Funcionarios;

-- RANK() e DENSE_RANK()
SELECT 
    Nome,
    Departamento,
    Salario,
    RANK() OVER (ORDER BY Salario DESC) AS Rank_Normal,
    DENSE_RANK() OVER (ORDER BY Salario DESC) AS Rank_Denso
FROM Funcionarios;

-- Particionamento com PARTITION BY
SELECT 
    Nome,
    Departamento,
    Salario,
    ROW_NUMBER() OVER (PARTITION BY Departamento ORDER BY Salario DESC) AS RankingDepartamento
FROM Funcionarios;

-- Funções de agregação como Window Functions
SELECT 
    Nome,
    Departamento,
    Salario,
    AVG(Salario) OVER (PARTITION BY Departamento) AS SalarioMedioDepartamento,
    SUM(Salario) OVER (PARTITION BY Departamento) AS TotalSalarioDepartamento
FROM Funcionarios;

-- LAG e LEAD - Acessar valores de linhas anteriores/posteriores
SELECT 
    Nome,
    Salario,
    LAG(Salario, 1) OVER (ORDER BY Salario) AS SalarioAnterior,
    LEAD(Salario, 1) OVER (ORDER BY Salario) AS ProximoSalario
FROM Funcionarios;

-- ═══════════════════════════════════════════════════════════════
-- 10. CTEs (COMMON TABLE EXPRESSIONS)
-- ═══════════════════════════════════════════════════════════════

-- CTE Simples
WITH FuncionariosAltoSalario AS (
    SELECT Nome, Departamento, Salario
    FROM Funcionarios
    WHERE Salario > 6000
)
SELECT * FROM FuncionariosAltoSalario
ORDER BY Salario DESC;

-- CTE com múltiplas definições
WITH 
EstatisticasDepartamento AS (
    SELECT 
        Departamento,
        COUNT(*) AS TotalFuncionarios,
        AVG(Salario) AS SalarioMedio
    FROM Funcionarios
    GROUP BY Departamento
),
DepartamentosGrandes AS (
    SELECT Departamento
    FROM EstatisticasDepartamento
    WHERE TotalFuncionarios > 10
)
SELECT 
    f.Nome,
    f.Departamento,
    f.Salario,
    e.SalarioMedio
FROM Funcionarios f
INNER JOIN EstatisticasDepartamento e ON f.Departamento = e.Departamento
INNER JOIN DepartamentosGrandes dg ON f.Departamento = dg.Departamento;

-- CTE Recursiva (exemplo: hierarquia organizacional)
WITH HierarquiaFuncionarios AS (
    -- Âncora: funcionários sem gerente (nível mais alto)
    SELECT 
        FuncionarioID,
        Nome,
        GerenteID,
        0 AS Nivel
    FROM Funcionarios
    WHERE GerenteID IS NULL
    
    UNION ALL
    
    -- Parte recursiva: funcionários com gerente
    SELECT 
        f.FuncionarioID,
        f.Nome,
        f.GerenteID,
        h.Nivel + 1
    FROM Funcionarios f
    INNER JOIN HierarquiaFuncionarios h ON f.GerenteID = h.FuncionarioID
)
SELECT 
    REPLICATE('  ', Nivel) + Nome AS NomeHierarquia,
    Nivel
FROM HierarquiaFuncionarios
ORDER BY Nivel, Nome;

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
    Nome,
    Salario,
    CASE 
        WHEN Salario < 3000 THEN 'Baixo'
        WHEN Salario BETWEEN 3000 AND 6000 THEN 'Médio'
        WHEN Salario > 6000 THEN 'Alto'
        ELSE 'Não Definido'
    END AS FaixaSalarial
FROM Funcionarios;

-- Função COALESCE para tratar valores NULL
SELECT 
    Nome,
    COALESCE(Email, 'email@naoinfo.com') AS EmailTratado,
    COALESCE(Telefone, 'Não informado') AS TelefoneTratado
FROM Funcionarios;

-- ═══════════════════════════════════════════════════════════════
-- 12. TÉCNICAS AVANÇADAS
-- ═══════════════════════════════════════════════════════════════

-- PIVOT - Transformar linhas em colunas
SELECT *
FROM (
    SELECT Departamento, Cargo, Salario
    FROM Funcionarios
) AS SourceTable
PIVOT (
    AVG(Salario)
    FOR Cargo IN ([Analista], [Gerente], [Diretor])
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

-- Exercício 1: Encontre os 5 funcionários com maior salário
SELECT TOP 5 Nome, Salario
FROM Funcionarios
ORDER BY Salario DESC;

-- Exercício 2: Calcule o salário médio por departamento, apenas para departamentos com mais de 3 funcionários
SELECT 
    Departamento,
    COUNT(*) AS TotalFuncionarios,
    AVG(Salario) AS SalarioMedio
FROM Funcionarios
GROUP BY Departamento
HAVING COUNT(*) > 3;

-- Exercício 3: Liste funcionários que ganham acima da média de seu departamento
SELECT 
    f1.Nome,
    f1.Departamento,
    f1.Salario,
    (
        SELECT AVG(f2.Salario)
        FROM Funcionarios f2
        WHERE f2.Departamento = f1.Departamento
    ) AS MediaDepartamento
FROM Funcionarios f1
WHERE f1.Salario > (
    SELECT AVG(f2.Salario)
    FROM Funcionarios f2
    WHERE f2.Departamento = f1.Departamento
);

-- Exercício 4: Ranking de funcionários por salário dentro de cada departamento
SELECT 
    Nome,
    Departamento,
    Salario,
    RANK() OVER (PARTITION BY Departamento ORDER BY Salario DESC) AS RankingDepartamento
FROM Funcionarios;

-- Exercício 5: Funcionários admitidos nos últimos 2 anos
SELECT 
    Nome,
    DataAdmissao,
    DATEDIFF(MONTH, DataAdmissao, GETDATE()) AS MesesEmpresa
FROM Funcionarios
WHERE DataAdmissao >= DATEADD(YEAR, -2, GETDATE())
ORDER BY DataAdmissao DESC;

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
6. Cuidado com funções em colunas no WHERE - podem impedir uso de índices
7. Use TOP ou OFFSET/FETCH para paginação
8. Considere usar CTEs para melhorar legibilidade de queries complexas
9. Monitore planos de execução para identificar gargalos
10. Use hints apenas quando necessário e com conhecimento
*/

-- Exemplo de paginação eficiente
SELECT Nome, Salario
FROM Funcionarios
ORDER BY Nome
OFFSET 20 ROWS
FETCH NEXT 10 ROWS ONLY;

-- Exemplo usando EXISTS (mais eficiente que IN em muitos casos)
SELECT Nome, Departamento
FROM Funcionarios f
WHERE EXISTS (
    SELECT 1
    FROM Projetos p
    WHERE p.ResponsavelID = f.FuncionarioID
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