/*
==============================================================================
                    AULA COMPLETA: FOR XML PATH vs STRING_AGG
                        Comparação Detalhada de Sintaxe e Performance
==============================================================================

Esta aula apresenta uma comparação completa entre as duas principais técnicas
de concatenação de strings em SQL Server:
- FOR XML PATH (Método tradicional - SQL Server 2005+)
- STRING_AGG (Método moderno - SQL Server 2017+)

Tópicos Abordados:
1. Introdução e Contexto Histórico
2. Sintaxe Básica de Cada Método
3. Exemplos Práticos Comparativos
4. Análise de Performance
5. Vantagens e Desvantagens
6. Casos de Uso Específicos
7. Migração de FOR XML PATH para STRING_AGG
8. Testes de Performance
9. Recomendações e Melhores Práticas

==============================================================================
*/

-- Configuração inicial
USE EcommerceDB;
GO

/*
==============================================================================
                        1. INTRODUÇÃO E CONTEXTO HISTÓRICO
==============================================================================
*/

/*
FOR XML PATH:
- Disponível desde SQL Server 2005
- Método "hack" usando funcionalidade XML para concatenação
- Sintaxe complexa mas muito flexível
- Compatível com versões antigas
- Requer uso de STUFF para remover delimitador inicial

STRING_AGG:
- Introduzido no SQL Server 2017
- Função nativa específica para concatenação
- Sintaxe simples e intuitiva
- Suporte nativo a ordenação com WITHIN GROUP
- Melhor performance em cenários específicos
*/

/*
==============================================================================
                        2. SINTAXE BÁSICA - COMPARAÇÃO LADO A LADO
==============================================================================
*/

-- Criação de dados de teste baseados no arquivo original
IF (OBJECT_ID('TEMPDB..#TabelaObjetos') IS NOT NULL)
    DROP TABLE #TabelaObjetos;

IF (OBJECT_ID('TEMPDB..#TabelaColunas') IS NOT NULL)
    DROP TABLE #TabelaColunas;

CREATE TABLE #TabelaObjetos (
    [object_id] INT,
    [object_name] NVARCHAR(261),
    CONSTRAINT PK_Objects PRIMARY KEY ([object_id])
);

CREATE TABLE #TabelaColunas (
    [object_id] INT NOT NULL,
    column_name SYSNAME,
    column_order INT,
    CONSTRAINT PK_Columns PRIMARY KEY ([object_id], column_name)
);

-- Inserindo dados de teste
INSERT #TabelaObjetos ([object_id], [object_name])
VALUES 
    (1, N'Produtos'),
    (2, N'Categorias'),
    (3, N'Clientes'),
    (4, N'Vendas');

INSERT #TabelaColunas ([object_id], column_name, column_order)
VALUES 
    (1, N'ProdutoID', 1),
    (1, N'NomeProduto', 2),
    (1, N'PrecoVenda', 3),
    (1, N'CategoriaID', 4),
    (2, N'CategoriaID', 1),
    (2, N'NomeCategoria', 2),
    (3, N'ClienteID', 1),
    (3, N'NomeCliente', 2),
    (3, N'Email', 3),
    (4, N'VendaID', 1),
    (4, N'DataVenda', 2),
    (4, N'ValorTotal', 3);

/*
==============================================================================
                        3. EXEMPLOS BÁSICOS - COMPARAÇÃO DIRETA
==============================================================================
*/

PRINT '=== EXEMPLO 1: CONCATENAÇÃO BÁSICA ===';

-- Método 1: FOR XML PATH (Tradicional)
SELECT 
    o.[object_name] AS Tabela,
    STUFF((
        SELECT N',' + c.column_name
        FROM #TabelaColunas AS c
        WHERE c.[object_id] = o.[object_id]
        FOR XML PATH(''), TYPE
    ).value('.[1]', 'NVARCHAR(MAX)'), 1, 1, N'') AS ColunasXML
FROM #TabelaObjetos AS o;

-- Método 2: STRING_AGG (Moderno)
SELECT 
    o.[object_name] AS Tabela,
    STRING_AGG(c.column_name, N',') AS ColunasStringAgg
FROM #TabelaObjetos AS o
INNER JOIN #TabelaColunas AS c ON o.[object_id] = c.[object_id]
GROUP BY o.[object_name];

/*
==============================================================================
                        4. CONCATENAÇÃO COM ORDENAÇÃO
==============================================================================
*/

PRINT '=== EXEMPLO 2: CONCATENAÇÃO COM ORDENAÇÃO ===';

-- Método 1: FOR XML PATH com ORDER BY
SELECT 
    o.[object_name] AS Tabela,
    STUFF((
        SELECT N',' + c.column_name
        FROM #TabelaColunas AS c
        WHERE c.[object_id] = o.[object_id]
        ORDER BY c.column_order -- Ordenação explícita
        FOR XML PATH(''), TYPE
    ).value('.[1]', 'NVARCHAR(MAX)'), 1, 1, N'') AS ColunasOrdenadas
FROM #TabelaObjetos AS o;

-- Método 2: STRING_AGG com WITHIN GROUP
SELECT 
    o.[object_name] AS Tabela,
    STRING_AGG(c.column_name, N',') WITHIN GROUP (ORDER BY c.column_order) AS ColunasOrdenadas
FROM #TabelaObjetos AS o
INNER JOIN #TabelaColunas AS c ON o.[object_id] = c.[object_id]
GROUP BY o.[object_name];

/*
==============================================================================
                        5. CONCATENAÇÃO COM FORMATAÇÃO COMPLEXA
==============================================================================
*/

PRINT '=== EXEMPLO 3: FORMATAÇÃO COMPLEXA ===';

-- Método 1: FOR XML PATH com formatação
SELECT 
    o.[object_name] AS Tabela,
    STUFF((
        SELECT N' | ' + UPPER(c.column_name) + N' (' + CAST(c.column_order AS NVARCHAR) + N')'
        FROM #TabelaColunas AS c
        WHERE c.[object_id] = o.[object_id]
        ORDER BY c.column_order
        FOR XML PATH(''), TYPE
    ).value('.[1]', 'NVARCHAR(MAX)'), 1, 3, N'') AS ColunasFormatadas
FROM #TabelaObjetos AS o;

-- Método 2: STRING_AGG com formatação
SELECT 
    o.[object_name] AS Tabela,
    STRING_AGG(
        UPPER(c.column_name) + N' (' + CAST(c.column_order AS NVARCHAR) + N')', 
        N' | '
    ) WITHIN GROUP (ORDER BY c.column_order) AS ColunasFormatadas
FROM #TabelaObjetos AS o
INNER JOIN #TabelaColunas AS c ON o.[object_id] = c.[object_id]
GROUP BY o.[object_name];

/*
==============================================================================
                        6. EXEMPLOS COM DADOS REAIS DO ECOMMERCE
==============================================================================
*/

PRINT '=== EXEMPLO 4: DADOS REAIS - PRODUTOS POR CATEGORIA ===';

-- Método 1: FOR XML PATH
SELECT 
    C.NomeCategoria,
    STUFF((
        SELECT N', ' + P.NomeProduto + N' (R$ ' + CAST(P.PrecoVenda AS NVARCHAR) + N')'
        FROM Produtos P
        WHERE P.CategoriaID = C.CategoriaID
        ORDER BY P.PrecoVenda DESC
        FOR XML PATH(''), TYPE
    ).value('.[1]', 'NVARCHAR(MAX)'), 1, 2, N'') AS ProdutosXML
FROM Categorias C
WHERE EXISTS (SELECT 1 FROM Produtos P WHERE P.CategoriaID = C.CategoriaID);

-- Método 2: STRING_AGG
SELECT 
    C.NomeCategoria,
    STRING_AGG(
        P.NomeProduto + N' (R$ ' + CAST(P.PrecoVenda AS NVARCHAR) + N')', 
        N', '
    ) WITHIN GROUP (ORDER BY P.PrecoVenda DESC) AS ProdutosStringAgg
FROM Categorias C
INNER JOIN Produtos P ON C.CategoriaID = P.CategoriaID
GROUP BY C.NomeCategoria;

/*
==============================================================================
                        7. TESTE DE PERFORMANCE - PREPARAÇÃO
==============================================================================
*/

PRINT '=== PREPARANDO DADOS PARA TESTE DE PERFORMANCE ===';

-- Criando tabela de teste com mais dados
IF (OBJECT_ID('TEMPDB..#TestePerformance') IS NOT NULL)
    DROP TABLE #TestePerformance;

CREATE TABLE #TestePerformance (
    GrupoID INT,
    Valor NVARCHAR(50),
    Ordem INT
);

-- Inserindo dados de teste (simulando cenário real)
DECLARE @i INT = 1;
DECLARE @grupo INT = 1;

WHILE @i <= 10000 -- 10.000 registros para teste
BEGIN
    INSERT INTO #TestePerformance (GrupoID, Valor, Ordem)
    VALUES (@grupo, N'Item_' + CAST(@i AS NVARCHAR), @i % 100);
    
    SET @i = @i + 1;
    
    -- Criar grupos de tamanhos variados
    IF @i % (50 + (@grupo % 20)) = 0
        SET @grupo = @grupo + 1;
END;

SELECT 
    COUNT(*) AS TotalRegistros,
    COUNT(DISTINCT GrupoID) AS TotalGrupos,
    AVG(CAST(ItensPerGrupo AS FLOAT)) AS MediaItensPerGrupo
FROM (
    SELECT GrupoID, COUNT(*) AS ItensPerGrupo
    FROM #TestePerformance
    GROUP BY GrupoID
) AS Stats;

/*
==============================================================================
                        8. TESTE DE PERFORMANCE - EXECUÇÃO
==============================================================================
*/

PRINT '=== TESTE DE PERFORMANCE: FOR XML PATH ===';

-- Limpando cache para teste justo
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;

DECLARE @inicio DATETIME2 = SYSDATETIME();

-- Teste FOR XML PATH
SELECT 
    GrupoID,
    STUFF((
        SELECT N',' + tp.Valor
        FROM #TestePerformance tp
        WHERE tp.GrupoID = t.GrupoID
        ORDER BY tp.Ordem
        FOR XML PATH(''), TYPE
    ).value('.[1]', 'NVARCHAR(MAX)'), 1, 1, N'') AS ValoresConcatenados
FROM (
    SELECT DISTINCT GrupoID 
    FROM #TestePerformance
) t
ORDER BY GrupoID;

DECLARE @tempoXML INT = DATEDIFF(MILLISECOND, @inicio, SYSDATETIME());
PRINT 'Tempo FOR XML PATH: ' + CAST(@tempoXML AS NVARCHAR) + ' ms';

PRINT '=== TESTE DE PERFORMANCE: STRING_AGG ===';

-- Limpando cache para teste justo
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;

SET @inicio = SYSDATETIME();

-- Teste STRING_AGG
SELECT 
    GrupoID,
    STRING_AGG(Valor, N',') WITHIN GROUP (ORDER BY Ordem) AS ValoresConcatenados
FROM #TestePerformance
GROUP BY GrupoID
ORDER BY GrupoID;

DECLARE @tempoStringAgg INT = DATEDIFF(MILLISECOND, @inicio, SYSDATETIME());
PRINT 'Tempo STRING_AGG: ' + CAST(@tempoStringAgg AS NVARCHAR) + ' ms';

-- Comparação de performance
PRINT '=== RESULTADO DA COMPARAÇÃO DE PERFORMANCE ===';
PRINT 'FOR XML PATH: ' + CAST(@tempoXML AS NVARCHAR) + ' ms';
PRINT 'STRING_AGG: ' + CAST(@tempoStringAgg AS NVARCHAR) + ' ms';
PRINT 'Diferença: ' + CAST(ABS(@tempoXML - @tempoStringAgg) AS NVARCHAR) + ' ms';
PRINT 'Método mais rápido: ' + 
    CASE 
        WHEN @tempoXML < @tempoStringAgg THEN 'FOR XML PATH'
        WHEN @tempoStringAgg < @tempoXML THEN 'STRING_AGG'
        ELSE 'Empate'
    END;

/*
==============================================================================
                        9. ANÁLISE DE PLANOS DE EXECUÇÃO
==============================================================================
*/

PRINT '=== ANÁLISE DE PLANOS DE EXECUÇÃO ===';

-- Habilitando estatísticas para análise
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

PRINT '--- Plano FOR XML PATH ---';
SELECT 
    C.NomeCategoria,
    STUFF((
        SELECT N',' + P.NomeProduto
        FROM Produtos P
        WHERE P.CategoriaID = C.CategoriaID
        FOR XML PATH(''), TYPE
    ).value('.[1]', 'NVARCHAR(MAX)'), 1, 1, N'') AS Produtos
FROM Categorias C;

PRINT '--- Plano STRING_AGG ---';
SELECT 
    C.NomeCategoria,
    STRING_AGG(P.NomeProduto, N',') AS Produtos
FROM Categorias C
INNER JOIN Produtos P ON C.CategoriaID = P.CategoriaID
GROUP BY C.NomeCategoria;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

/*
==============================================================================
                        10. CASOS DE USO ESPECÍFICOS
==============================================================================
*/

PRINT '=== CASO 1: CONCATENAÇÃO CONDICIONAL ===';

-- FOR XML PATH com condições
SELECT 
    C.NomeCategoria,
    STUFF((
        SELECT N',' + P.NomeProduto
        FROM Produtos P
        WHERE P.CategoriaID = C.CategoriaID
          AND P.PrecoVenda > 50 -- Condição específica
        FOR XML PATH(''), TYPE
    ).value('.[1]', 'NVARCHAR(MAX)'), 1, 1, N'') AS ProdutosCaros
FROM Categorias C;

-- STRING_AGG com condições (usando CASE)
SELECT 
    C.NomeCategoria,
    STRING_AGG(
        CASE WHEN P.PrecoVenda > 50 THEN P.NomeProduto END, 
        N','
    ) AS ProdutosCaros
FROM Categorias C
INNER JOIN Produtos P ON C.CategoriaID = P.CategoriaID
GROUP BY C.NomeCategoria;

PRINT '=== CASO 2: CONCATENAÇÃO COM LIMITE ===';

-- FOR XML PATH com TOP
SELECT 
    C.NomeCategoria,
    STUFF((
        SELECT TOP 3 N',' + P.NomeProduto
        FROM Produtos P
        WHERE P.CategoriaID = C.CategoriaID
        ORDER BY P.PrecoVenda DESC
        FOR XML PATH(''), TYPE
    ).value('.[1]', 'NVARCHAR(MAX)'), 1, 1, N'') AS Top3Produtos
FROM Categorias C;

-- STRING_AGG não tem suporte nativo a TOP, precisa de subconsulta
SELECT 
    NomeCategoria,
    STRING_AGG(NomeProduto, N',') AS Top3Produtos
FROM (
    SELECT 
        C.NomeCategoria,
        P.NomeProduto,
        ROW_NUMBER() OVER (PARTITION BY C.CategoriaID ORDER BY P.PrecoVenda DESC) AS rn
    FROM Categorias C
    INNER JOIN Produtos P ON C.CategoriaID = P.CategoriaID
) ranked
WHERE rn <= 3
GROUP BY NomeCategoria;

/*
==============================================================================
                        11. TRATAMENTO DE CARACTERES ESPECIAIS
==============================================================================
*/

PRINT '=== TRATAMENTO DE CARACTERES ESPECIAIS ===';

-- Criando dados com caracteres especiais
DECLARE @TabelaEspecial TABLE (
    ID INT,
    Texto NVARCHAR(100)
);

INSERT INTO @TabelaEspecial VALUES
    (1, N'Texto com & comercial'),
    (1, N'Texto com < menor'),
    (1, N'Texto com > maior'),
    (1, N'Texto "com aspas"'),
    (2, N'Texto normal'),
    (2, N'Outro texto');

-- FOR XML PATH (escapa automaticamente caracteres XML)
SELECT 
    ID,
    STUFF((
        SELECT N',' + Texto
        FROM @TabelaEspecial te
        WHERE te.ID = t.ID
        FOR XML PATH(''), TYPE
    ).value('.[1]', 'NVARCHAR(MAX)'), 1, 1, N'') AS TextosXML
FROM (SELECT DISTINCT ID FROM @TabelaEspecial) t;

-- STRING_AGG (não escapa caracteres)
SELECT 
    ID,
    STRING_AGG(Texto, N',') AS TextosStringAgg
FROM @TabelaEspecial
GROUP BY ID;

/*
==============================================================================
                        12. MIGRAÇÃO DE FOR XML PATH PARA STRING_AGG
==============================================================================
*/

PRINT '=== GUIA DE MIGRAÇÃO ===';

-- Padrão comum de migração:
/*
DE (FOR XML PATH):
STUFF((
    SELECT ',' + campo
    FROM tabela
    WHERE condicao
    ORDER BY campo
    FOR XML PATH(''), TYPE
).value('.[1]', 'NVARCHAR(MAX)'), 1, 1, '')

PARA (STRING_AGG):
STRING_AGG(campo, ',') WITHIN GROUP (ORDER BY campo)
*/

-- Exemplo de migração completa
PRINT '--- ANTES (FOR XML PATH) ---';
SELECT 
    'Exemplo de migração' AS Descricao,
    STUFF((
        SELECT N',' + column_name
        FROM #TabelaColunas
        WHERE [object_id] = 1
        ORDER BY column_order
        FOR XML PATH(''), TYPE
    ).value('.[1]', 'NVARCHAR(MAX)'), 1, 1, N'') AS Resultado;

PRINT '--- DEPOIS (STRING_AGG) ---';
SELECT 
    'Exemplo de migração' AS Descricao,
    STRING_AGG(column_name, N',') WITHIN GROUP (ORDER BY column_order) AS Resultado
FROM #TabelaColunas
WHERE [object_id] = 1;

/*
==============================================================================
                        13. VANTAGENS E DESVANTAGENS
==============================================================================
*/

/*
FOR XML PATH:

VANTAGENS:
+ Disponível em versões antigas (SQL Server 2005+)
+ Muito flexível para formatação complexa
+ Suporte a subconsultas correlacionadas
+ Funciona bem com TOP e condições complexas
+ Escapa automaticamente caracteres XML

DESVANTAGENS:
- Sintaxe complexa e não intuitiva
- Requer STUFF para remover delimitador inicial
- Pode ser mais lento em alguns cenários
- Código menos legível
- Não é uma função específica para concatenação

STRING_AGG:

VANTAGENS:
+ Sintaxe simples e intuitiva
+ Função nativa específica para concatenação
+ Suporte nativo a ordenação (WITHIN GROUP)
+ Melhor performance em muitos casos
+ Código mais limpo e legível
+ Padrão SQL (ANSI SQL:2016)

DESVANTAGENS:
- Disponível apenas no SQL Server 2017+
- Menos flexível para formatação complexa
- Não suporta TOP diretamente
- Não escapa caracteres especiais
- Requer GROUP BY explícito
*/

/*
==============================================================================
                        14. RECOMENDAÇÕES E MELHORES PRÁTICAS
==============================================================================
*/

/*
RECOMENDAÇÕES:

1. PARA NOVOS PROJETOS (SQL Server 2017+):
   - Use STRING_AGG sempre que possível
   - Reserve FOR XML PATH para casos específicos

2. PARA SISTEMAS LEGADOS:
   - Mantenha FOR XML PATH se já funciona bem
   - Considere migração gradual durante atualizações

3. ESCOLHA FOR XML PATH QUANDO:
   - Precisar de compatibilidade com versões antigas
   - Necessitar de formatação muito complexa
   - Usar subconsultas correlacionadas complexas
   - Precisar de TOP com concatenação

4. ESCOLHA STRING_AGG QUANDO:
   - Estiver no SQL Server 2017+
   - Precisar de código mais limpo
   - Performance for crítica
   - Quiser seguir padrões SQL modernos

5. PERFORMANCE:
   - Teste ambos os métodos com seus dados reais
   - STRING_AGG geralmente é mais rápido
   - FOR XML PATH pode ser melhor em casos específicos

6. MANUTENIBILIDADE:
   - STRING_AGG é mais fácil de entender e manter
   - FOR XML PATH requer mais documentação
*/

/*
==============================================================================
                        15. EXERCÍCIOS PRÁTICOS
==============================================================================
*/

PRINT '=== EXERCÍCIO 1: CONVERSÃO DE SINTAXE ===';
-- Converta esta consulta FOR XML PATH para STRING_AGG:

-- Original (FOR XML PATH):
SELECT 
    V.ClienteID,
    STUFF((
        SELECT N'; ' + CAST(IV.ProdutoID AS NVARCHAR) + N':' + CAST(IV.Quantidade AS NVARCHAR)
        FROM ItensVenda IV
        INNER JOIN Vendas V2 ON IV.VendaID = V2.VendaID
        WHERE V2.ClienteID = V.ClienteID
        ORDER BY IV.ProdutoID
        FOR XML PATH(''), TYPE
    ).value('.[1]', 'NVARCHAR(MAX)'), 1, 2, N'') AS ProdutosComprados
FROM Vendas V
GROUP BY V.ClienteID;

-- Convertido (STRING_AGG):
SELECT 
    V.ClienteID,
    STRING_AGG(
        CAST(IV.ProdutoID AS NVARCHAR) + N':' + CAST(IV.Quantidade AS NVARCHAR), 
        N'; '
    ) WITHIN GROUP (ORDER BY IV.ProdutoID) AS ProdutosComprados
FROM Vendas V
INNER JOIN ItensVenda IV ON V.VendaID = IV.VendaID
GROUP BY V.ClienteID;

PRINT '=== EXERCÍCIO 2: ANÁLISE DE PERFORMANCE ===';
-- Compare a performance das duas consultas acima com STATISTICS TIME ON

/*
==============================================================================
                        16. LIMPEZA E CONCLUSÃO
==============================================================================
*/

-- Limpando objetos temporários
IF (OBJECT_ID('TEMPDB..#TabelaObjetos') IS NOT NULL)
    DROP TABLE #TabelaObjetos;

IF (OBJECT_ID('TEMPDB..#TabelaColunas') IS NOT NULL)
    DROP TABLE #TabelaColunas;

IF (OBJECT_ID('TEMPDB..#TestePerformance') IS NOT NULL)
    DROP TABLE #TestePerformance;

PRINT '=== CONCLUSÃO ===';
PRINT 'Esta aula demonstrou as principais diferenças entre FOR XML PATH e STRING_AGG.';
PRINT 'A escolha entre eles deve considerar:';
PRINT '1. Versão do SQL Server disponível';
PRINT '2. Complexidade da formatação necessária';
PRINT '3. Requisitos de performance';
PRINT '4. Manutenibilidade do código';
PRINT '';
PRINT 'Para novos projetos no SQL Server 2017+, recomenda-se STRING_AGG.';
PRINT 'Para sistemas legados, FOR XML PATH continua sendo uma solução válida.';

/*
==============================================================================
                                RESUMO FINAL
==============================================================================

Comparação Resumida:

| Aspecto              | FOR XML PATH        | STRING_AGG          |
|---------------------|--------------------|--------------------- |
| Versão Mínima       | SQL Server 2005    | SQL Server 2017     |
| Sintaxe             | Complexa           | Simples              |
| Performance         | Boa                | Melhor (geralmente)  |
| Flexibilidade       | Alta               | Média                |
| Legibilidade        | Baixa              | Alta                 |
| Manutenibilidade    | Difícil            | Fácil                |
| Padrão SQL          | Não                | Sim (ANSI SQL:2016)  |
| Escape de Caracteres| Automático (XML)   | Manual               |
| Suporte a TOP       | Nativo             | Requer subconsulta   |
| Ordenação           | ORDER BY           | WITHIN GROUP         |

Recomendação Geral:
- Use STRING_AGG para novos projetos (SQL Server 2017+)
- Mantenha FOR XML PATH em sistemas legados funcionais
- Considere migração gradual durante atualizações de versão

==============================================================================
*/