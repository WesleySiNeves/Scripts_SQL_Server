/*
═══════════════════════════════════════════════════════════════
                    AULA COMPLETA - CLÁUSULA WHERE
                        SQL Server T-SQL
═══════════════════════════════════════════════════════════════

Autor: Wesley Neves
Data: 2024
Descrição: Aula completa sobre a cláusula WHERE em T-SQL,
           do básico ao avançado, com exemplos práticos.

Pré-requisito: Execute o script 2.CriacaoTabelas.sql para criar
               o banco de dados EcommerceDB antes de executar
               os exemplos desta aula.

═══════════════════════════════════════════════════════════════
*/

-- Configuração inicial
USE EcommerceDB;
GO

-- ═══════════════════════════════════════════════════════════════
-- 1. INTRODUÇÃO À CLÁUSULA WHERE
-- ═══════════════════════════════════════════════════════════════

/*
A cláusula WHERE é usada para filtrar registros em consultas SQL.
Ela especifica uma condição que deve ser atendida para que um registro
seja incluído no resultado da consulta.

Sintaxe básica:
SELECT colunas
FROM tabela
WHERE condição;
*/

-- ═══════════════════════════════════════════════════════════════
-- 2. OPERADORES DE COMPARAÇÃO
-- ═══════════════════════════════════════════════════════════════

-- Operador = (igual)
SELECT NomeProduto, PrecoVenda
FROM Produtos
WHERE CategoriaID = 1;

-- Operador <> ou != (diferente)
SELECT NomeProduto, PrecoVenda
FROM Produtos
WHERE CategoriaID <> 1;

-- Operador > (maior que)
SELECT NomeProduto, PrecoVenda
FROM Produtos
WHERE PrecoVenda > 500;

-- Operador < (menor que)
SELECT NomeProduto, PrecoVenda
FROM Produtos
WHERE PrecoVenda < 100;

-- Operador >= (maior ou igual)
SELECT NomeProduto, PrecoVenda
FROM Produtos
WHERE PrecoVenda >= 500;

-- Operador <= (menor ou igual)
SELECT NomeProduto, PrecoVenda
FROM Produtos
WHERE PrecoVenda <= 100;

-- ═══════════════════════════════════════════════════════════════
-- 3. OPERADORES LÓGICOS
-- ═══════════════════════════════════════════════════════════════

-- Operador AND - Todas as condições devem ser verdadeiras
SELECT NomeProduto, PrecoVenda, CategoriaID
FROM Produtos
WHERE PrecoVenda > 100 AND CategoriaID = 1;

-- Operador OR - Pelo menos uma condição deve ser verdadeira
SELECT NomeProduto, PrecoVenda, CategoriaID
FROM Produtos
WHERE PrecoVenda > 1000 OR CategoriaID = 3;

-- Operador NOT - Nega a condição
SELECT NomeProduto, PrecoVenda
FROM Produtos
WHERE NOT PrecoVenda > 500;

-- Combinando operadores lógicos com parênteses
SELECT NomeProduto, PrecoVenda, CategoriaID
FROM Produtos
WHERE (PrecoVenda > 500 AND CategoriaID = 1) OR (PrecoVenda < 100 AND CategoriaID = 2);

-- ═══════════════════════════════════════════════════════════════
-- 4. OPERADOR IN
-- ═══════════════════════════════════════════════════════════════

-- IN - Verifica se o valor está em uma lista de valores
SELECT NomeProduto, CategoriaID
FROM Produtos
WHERE CategoriaID IN (1, 2, 3);

-- NOT IN - Verifica se o valor NÃO está em uma lista
SELECT NomeProduto, CategoriaID
FROM Produtos
WHERE CategoriaID NOT IN (1, 2);

-- IN com subconsulta
SELECT NomeProduto, CategoriaID
FROM Produtos
WHERE CategoriaID IN (
    SELECT CategoriaID 
    FROM Categorias 
    WHERE NomeCategoria LIKE '%Eletrônicos%'
);

-- ═══════════════════════════════════════════════════════════════
-- 5. OPERADOR BETWEEN
-- ═══════════════════════════════════════════════════════════════

-- BETWEEN - Verifica se o valor está dentro de um intervalo (inclusive)
SELECT NomeProduto, PrecoVenda
FROM Produtos
WHERE PrecoVenda BETWEEN 100 AND 500;

-- NOT BETWEEN - Verifica se o valor NÃO está no intervalo
SELECT NomeProduto, PrecoVenda
FROM Produtos
WHERE PrecoVenda NOT BETWEEN 100 AND 500;

-- BETWEEN com datas
SELECT VendaID, DataVenda, ValorTotal
FROM Vendas
WHERE DataVenda BETWEEN '2024-01-01' AND '2024-12-31';

-- ═══════════════════════════════════════════════════════════════
-- 6. OPERADOR LIKE E WILDCARDS
-- ═══════════════════════════════════════════════════════════════

-- LIKE com % (qualquer sequência de caracteres)
SELECT NomeProduto
FROM Produtos
WHERE NomeProduto LIKE 'Smart%'; -- Produtos que começam com "Smart"

SELECT NomeProduto
FROM Produtos
WHERE NomeProduto LIKE '%Phone%'; -- Produtos que contêm "Phone"

SELECT NomeProduto
FROM Produtos
WHERE NomeProduto LIKE '%Pro'; -- Produtos que terminam com "Pro"

-- LIKE com _ (um único caractere)
SELECT NomeProduto
FROM Produtos
WHERE NomeProduto LIKE 'Smart_hone'; -- Um caractere entre "Smart" e "hone"

-- LIKE com [] (qualquer caractere dentro dos colchetes)
SELECT NomeCliente
FROM Clientes
WHERE NomeCliente LIKE '[ABC]%'; -- Nomes que começam com A, B ou C

-- LIKE com [^] ou [!] (qualquer caractere EXCETO os especificados)
SELECT NomeCliente
FROM Clientes
WHERE NomeCliente LIKE '[^ABC]%'; -- Nomes que NÃO começam com A, B ou C

-- LIKE com intervalo de caracteres
SELECT NomeCliente
FROM Clientes
WHERE NomeCliente LIKE '[A-M]%'; -- Nomes que começam de A até M

-- ═══════════════════════════════════════════════════════════════
-- 7. OPERADOR LIKE - TÉCNICAS AVANÇADAS
-- ═══════════════════════════════════════════════════════════════

-- Buscar apenas códigos que começam com números (baseado nos arquivos existentes)
SELECT ProdutoID, NomeProduto
FROM Produtos
WHERE CAST(ProdutoID AS VARCHAR) LIKE '[0-9]%';

-- Buscar códigos que NÃO começam com números
SELECT ProdutoID, NomeProduto
FROM Produtos
WHERE CAST(ProdutoID AS VARCHAR) NOT LIKE '[0-9]%';

-- Buscar nomes com acentos (adaptado do arquivo existente)
SELECT NomeCliente
FROM Clientes
WHERE NomeCliente COLLATE SQL_Latin1_General_CP1_CI_AS LIKE '%[áéíóúàèìòùâêîôûãõç]%';

-- Múltiplos padrões LIKE usando UNION (baseado nos arquivos existentes)
SELECT NomeProduto
FROM Produtos
WHERE NomeProduto LIKE '%Smart%'
UNION
SELECT NomeProduto
FROM Produtos
WHERE NomeProduto LIKE '%Pro%'
UNION
SELECT NomeProduto
FROM Produtos
WHERE NomeProduto LIKE '%Max%';

-- ═══════════════════════════════════════════════════════════════
-- 8. MÚLTIPLOS LIKES COM JOIN (TÉCNICA AVANÇADA)
-- ═══════════════════════════════════════════════════════════════

-- Técnica para aplicar múltiplos padrões LIKE de forma eficiente
-- (baseado no arquivo "3.Fazendo Joins com Multiplos Likes.sql")
SELECT p.NomeProduto, p.PrecoVenda
FROM Produtos p
INNER JOIN (
    SELECT '%Smart%' AS Padrao
    UNION ALL
    SELECT '%Pro%' AS Padrao
    UNION ALL
    SELECT '%Max%' AS Padrao
    UNION ALL
    SELECT '%Ultra%' AS Padrao
) Padroes ON p.NomeProduto LIKE Padroes.Padrao;

-- Exemplo mais complexo com tabela de filtros
-- (baseado no arquivo "3.Fazendo Multiplos Likes.sql")
DECLARE @FiltrosProdutos TABLE (Padrao VARCHAR(100));
INSERT INTO @FiltrosProdutos (Padrao)
VALUES ('%Smart%'), ('%Pro%'), ('%Max%'), ('%Ultra%'), ('%Premium%');

SELECT p.ProdutoID, p.NomeProduto, p.PrecoVenda
FROM Produtos p
INNER JOIN (
    SELECT fp.Padrao
    FROM @FiltrosProdutos fp
) Filtros ON p.NomeProduto LIKE Filtros.Padrao
ORDER BY p.PrecoVenda DESC;

-- ═══════════════════════════════════════════════════════════════
-- 9. VERIFICAÇÃO DE VALORES NULL
-- ═══════════════════════════════════════════════════════════════

-- IS NULL - Verifica valores nulos
SELECT NomeProduto, ImagemURL
FROM Produtos
WHERE ImagemURL IS NULL;

-- IS NOT NULL - Verifica valores não nulos
SELECT NomeProduto, ImagemURL
FROM Produtos
WHERE ImagemURL IS NOT NULL;

-- Combinando com outros operadores
SELECT NomeProduto, PrecoVenda, ImagemURL
FROM Produtos
WHERE PrecoVenda > 100 AND ImagemURL IS NOT NULL;

-- ═══════════════════════════════════════════════════════════════
-- 10. OPERADOR EXISTS
-- ═══════════════════════════════════════════════════════════════

-- EXISTS - Verifica se uma subconsulta retorna pelo menos um registro
SELECT NomeProduto, PrecoVenda
FROM Produtos p
WHERE EXISTS (
    SELECT 1
    FROM ItensVenda iv
    WHERE iv.ProdutoID = p.ProdutoID
);

-- NOT EXISTS - Verifica se uma subconsulta NÃO retorna registros
SELECT NomeProduto, PrecoVenda
FROM Produtos p
WHERE NOT EXISTS (
    SELECT 1
    FROM ItensVenda iv
    WHERE iv.ProdutoID = p.ProdutoID
);

-- ═══════════════════════════════════════════════════════════════
-- 11. FUNÇÕES DE DATA NO WHERE
-- ═══════════════════════════════════════════════════════════════

-- Filtrar por ano
SELECT VendaID, DataVenda, ValorTotal
FROM Vendas
WHERE YEAR(DataVenda) = 2024;

-- Filtrar por mês
SELECT VendaID, DataVenda, ValorTotal
FROM Vendas
WHERE MONTH(DataVenda) = 12;

-- Filtrar por dia da semana
SELECT VendaID, DataVenda, ValorTotal
FROM Vendas
WHERE DATEPART(WEEKDAY, DataVenda) = 1; -- Domingo

-- Filtrar registros dos últimos 30 dias
SELECT VendaID, DataVenda, ValorTotal
FROM Vendas
WHERE DataVenda >= DATEADD(DAY, -30, GETDATE());

-- ═══════════════════════════════════════════════════════════════
-- 12. FUNÇÕES DE STRING NO WHERE
-- ═══════════════════════════════════════════════════════════════

-- LEN - Filtrar por comprimento da string
SELECT NomeCliente
FROM Clientes
WHERE LEN(NomeCliente) > 10;

-- UPPER/LOWER - Comparação sem distinção de maiúsculas/minúsculas
SELECT NomeProduto
FROM Produtos
WHERE UPPER(NomeProduto) LIKE '%SMART%';

-- LEFT/RIGHT - Filtrar por caracteres à esquerda/direita
SELECT NomeCliente
FROM Clientes
WHERE LEFT(NomeCliente, 1) = 'A';

-- SUBSTRING - Filtrar por substring
SELECT NomeProduto
FROM Produtos
WHERE SUBSTRING(NomeProduto, 1, 5) = 'Smart';

-- CHARINDEX - Verificar se contém substring
SELECT NomeProduto
FROM Produtos
WHERE CHARINDEX('Pro', NomeProduto) > 0;

-- ═══════════════════════════════════════════════════════════════
-- 13. EXPRESSÕES CASE NO WHERE
-- ═══════════════════════════════════════════════════════════════

-- Usando CASE para criar condições complexas
SELECT NomeProduto, PrecoVenda,
       CASE 
           WHEN PrecoVenda < 100 THEN 'Barato'
           WHEN PrecoVenda BETWEEN 100 AND 500 THEN 'Médio'
           ELSE 'Caro'
       END AS FaixaPreco
FROM Produtos
WHERE CASE 
          WHEN PrecoVenda < 100 THEN 'Barato'
          WHEN PrecoVenda BETWEEN 100 AND 500 THEN 'Médio'
          ELSE 'Caro'
      END = 'Caro';

-- ═══════════════════════════════════════════════════════════════
-- 14. SUBCONSULTAS NO WHERE
-- ═══════════════════════════════════════════════════════════════

-- Subconsulta simples
SELECT NomeProduto, PrecoVenda
FROM Produtos
WHERE PrecoVenda > (
    SELECT AVG(PrecoVenda)
    FROM Produtos
);

-- Subconsulta correlacionada
SELECT p1.NomeProduto, p1.PrecoVenda, p1.CategoriaID
FROM Produtos p1
WHERE p1.PrecoVenda > (
    SELECT AVG(p2.PrecoVenda)
    FROM Produtos p2
    WHERE p2.CategoriaID = p1.CategoriaID
);

-- Subconsulta com ANY/SOME
SELECT NomeProduto, PrecoVenda
FROM Produtos
WHERE PrecoVenda > ANY (
    SELECT PrecoVenda
    FROM Produtos
    WHERE CategoriaID = 1
);

-- Subconsulta com ALL
SELECT NomeProduto, PrecoVenda
FROM Produtos
WHERE PrecoVenda > ALL (
    SELECT PrecoVenda
    FROM Produtos
    WHERE CategoriaID = 1
);

-- ═══════════════════════════════════════════════════════════════
-- 15. PERFORMANCE E OTIMIZAÇÃO
-- ═══════════════════════════════════════════════════════════════

-- ❌ EVITE: Funções em colunas indexadas
-- SELECT * FROM Vendas WHERE YEAR(DataVenda) = 2024;

-- ✅ PREFIRA: Filtros diretos
SELECT VendaID, DataVenda, ValorTotal
FROM Vendas
WHERE DataVenda >= '2024-01-01' AND DataVenda < '2025-01-01';

-- ❌ EVITE: OR com muitas condições
-- SELECT * FROM Produtos WHERE CategoriaID = 1 OR CategoriaID = 2 OR CategoriaID = 3;

-- ✅ PREFIRA: IN
SELECT NomeProduto, CategoriaID
FROM Produtos
WHERE CategoriaID IN (1, 2, 3);

-- ❌ EVITE: LIKE com wildcard no início
-- SELECT * FROM Produtos WHERE NomeProduto LIKE '%Phone';

-- ✅ PREFIRA: LIKE com wildcard no final (quando possível)
SELECT NomeProduto
FROM Produtos
WHERE NomeProduto LIKE 'Smart%';

-- ❌ EVITE: NOT IN com valores NULL
-- SELECT * FROM Produtos WHERE CategoriaID NOT IN (SELECT CategoriaID FROM Categorias WHERE Ativo IS NULL);

-- ✅ PREFIRA: NOT EXISTS ou IS NOT NULL
SELECT p.NomeProduto
FROM Produtos p
WHERE NOT EXISTS (
    SELECT 1
    FROM Categorias c
    WHERE c.CategoriaID = p.CategoriaID
    AND c.Ativo IS NULL
);

-- ═══════════════════════════════════════════════════════════════
-- 16. EXERCÍCIOS PRÁTICOS
-- ═══════════════════════════════════════════════════════════════

-- Exercício 1: Produtos caros de uma categoria específica
-- SELECT NomeProduto, PrecoVenda FROM Produtos WHERE CategoriaID = 1 AND PrecoVenda > 500;

-- Exercício 2: Clientes cujo nome contém "Silva" ou "Santos"
-- SELECT NomeCliente FROM Clientes WHERE NomeCliente LIKE '%Silva%' OR NomeCliente LIKE '%Santos%';

-- Exercício 3: Produtos sem imagem e com estoque baixo
-- SELECT NomeProduto, EstoqueAtual FROM Produtos WHERE ImagemURL IS NULL AND EstoqueAtual < 10;

-- Exercício 4: Vendas do último trimestre
-- SELECT VendaID, DataVenda, ValorTotal FROM Vendas WHERE DataVenda >= DATEADD(QUARTER, -1, GETDATE());

-- Exercício 5: Produtos mais caros que a média de sua categoria
-- SELECT p1.NomeProduto, p1.PrecoVenda, p1.CategoriaID
-- FROM Produtos p1
-- WHERE p1.PrecoVenda > (
--     SELECT AVG(p2.PrecoVenda)
--     FROM Produtos p2
--     WHERE p2.CategoriaID = p1.CategoriaID
-- );

-- ═══════════════════════════════════════════════════════════════
-- 17. DICAS IMPORTANTES
-- ═══════════════════════════════════════════════════════════════

/*
DICAS DE BOAS PRÁTICAS:

1. Use parênteses para deixar clara a precedência dos operadores lógicos
2. Prefira EXISTS ao invés de IN quando usar subconsultas
3. Evite funções em colunas indexadas no WHERE
4. Use BETWEEN para intervalos ao invés de >= AND <=
5. Cuidado com valores NULL - use IS NULL/IS NOT NULL
6. Para performance, coloque as condições mais seletivas primeiro
7. Use índices apropriados nas colunas frequentemente filtradas
8. Teste sempre a performance de suas consultas
9. Documente consultas complexas com comentários
10. Use COLLATE quando necessário para comparações de texto

ORDEM DE PRECEDÊNCIA DOS OPERADORES:
1. Parênteses ()
2. Operadores aritméticos (*, /, +, -)
3. Operadores de comparação (=, <>, <, >, <=, >=, LIKE, IN, BETWEEN)
4. NOT
5. AND
6. OR

LEMBRE-SE:
- NULL não é igual a NULL (use IS NULL)
- Strings são case-sensitive por padrão (use COLLATE se necessário)
- Datas devem estar no formato correto (YYYY-MM-DD)
- Performance é crucial em tabelas grandes
*/

-- ═══════════════════════════════════════════════════════════════
-- FIM DA AULA
-- ═══════════════════════════════════════════════════════════════

/*
Esta aula cobriu todos os aspectos importantes da cláusula WHERE:
- Operadores básicos de comparação
- Operadores lógicos (AND, OR, NOT)
- Operadores especiais (IN, BETWEEN, LIKE, EXISTS)
- Técnicas avançadas com wildcards
- Múltiplos padrões LIKE
- Funções de data e string
- Subconsultas
- Otimização e performance
- Exercícios práticos

Próximos passos:
- Pratique com os exercícios propostos
- Experimente diferentes combinações de operadores
- Analise os planos de execução de suas consultas
- Estude sobre índices para otimizar suas consultas WHERE
*/