-- =====================================================
-- CURSO SQL SERVER - MÓDULO 03: FUNÇÕES E OPERADORES
-- Arquivo: 03_funcoes_data.sql
-- Tópico: Funções de Data e Hora
-- =====================================================

-- ÍNDICE:
-- 1. Funções Básicas de Data
-- 2. Conversão de Milissegundos
-- 3. Cálculos com TIME
-- 4. Formatação de Datas
-- 5. Divisão de Períodos
-- 6. Exercícios Práticos

-- =====================================================
-- 1. FUNÇÕES BÁSICAS DE DATA E HORA
-- =====================================================

-- Exemplo 1: Funções de obtenção de data atual
SELECT GETDATE() AS DataAtual,
       GETUTCDATE() AS DataUTC,
       SYSDATETIME() AS DataSistema,
       CURRENT_TIMESTAMP AS TimestampAtual;

-- Exemplo 2: Extraindo partes da data
DECLARE @data DATETIME = GETDATE();

SELECT @data AS DataCompleta,
       YEAR(@data) AS Ano,
       MONTH(@data) AS Mes,
       DAY(@data) AS Dia,
       DATEPART(HOUR, @data) AS Hora,
       DATEPART(MINUTE, @data) AS Minuto,
       DATEPART(SECOND, @data) AS Segundo,
       DATEPART(WEEKDAY, @data) AS DiaSemana,
       DATEPART(WEEK, @data) AS SemanaAno;

-- Exemplo 3: Operações com DATEADD e DATEDIFF
SELECT GETDATE() AS DataAtual,
       DATEADD(DAY, 30, GETDATE()) AS Mais30Dias,
       DATEADD(MONTH, -6, GETDATE()) AS Menos6Meses,
       DATEADD(YEAR, 1, GETDATE()) AS MaisUmAno,
       DATEDIFF(DAY, '2024-01-01', GETDATE()) AS DiasDesdeAnoNovo,
       DATEDIFF(MONTH, '2020-01-01', GETDATE()) AS MesesDesde2020;

-- =====================================================
-- 2. CONVERSÃO DE MILISSEGUNDOS PARA SEGUNDOS
-- =====================================================

-- Exemplo 1: Converter milissegundos para formato TIME
DECLARE @milissegundos INT = 15168; -- 15.168 milissegundos

SELECT @milissegundos AS Milissegundos,
       CONVERT(TIME, DATEADD(ms, @milissegundos, 0)) AS [Tempo em Segundos],
       CONVERT(VARCHAR(12), DATEADD(ms, @milissegundos, 0), 114) AS [Formato HH:MM:SS:mmm];

-- Exemplo 2: Diferentes conversões de tempo
SELECT 3661000 AS Milissegundos, -- 1 hora, 1 minuto, 1 segundo
       CONVERT(TIME, DATEADD(ms, 3661000, 0)) AS TempoFormatado,
       CONVERT(VARCHAR(12), DATEADD(ms, 3661000, 0), 108) AS FormatoHHMMSS;

-- Exemplo 3: Cálculo de duração em diferentes unidades
DECLARE @duracao_ms INT = 125000; -- 125 segundos

SELECT @duracao_ms AS Milissegundos,
       @duracao_ms / 1000 AS Segundos,
       @duracao_ms / 60000 AS Minutos,
       CONVERT(TIME, DATEADD(ms, @duracao_ms, 0)) AS TempoFormatado;

-- =====================================================
-- 3. CÁLCULOS COM TIME
-- =====================================================

-- Exemplo 1: Diferença entre horários
DECLARE @Campo1 VARCHAR(5) = '15:30';
DECLARE @Campo2 VARCHAR(5) = '17:10';

SELECT @Campo1 AS HorarioInicial,
       @Campo2 AS HorarioFinal,
       CONVERT(VARCHAR(5), 
               DATEADD(SECOND, 
                      DATEDIFF(SECOND, CAST(@Campo1 AS TIME(0)), CAST(@Campo2 AS TIME(0))), 
                      0), 
               108) AS DiferencaTempo;

-- Exemplo 2: Soma de horários
DECLARE @tempo1 TIME = '02:30:00';
DECLARE @tempo2 TIME = '01:45:00';

SELECT @tempo1 AS Tempo1,
       @tempo2 AS Tempo2,
       CONVERT(TIME, DATEADD(SECOND, 
                            DATEDIFF(SECOND, '00:00:00', @tempo1) + 
                            DATEDIFF(SECOND, '00:00:00', @tempo2), 
                            '00:00:00')) AS SomaTempos;

-- Exemplo 3: Cálculo de horas trabalhadas
DECLARE @entrada TIME = '08:00:00';
DECLARE @saida TIME = '17:30:00';
DECLARE @almoco_inicio TIME = '12:00:00';
DECLARE @almoco_fim TIME = '13:00:00';

SELECT @entrada AS Entrada,
       @saida AS Saida,
       DATEDIFF(MINUTE, @entrada, @saida) AS MinutosTotais,
       DATEDIFF(MINUTE, @almoco_inicio, @almoco_fim) AS MinutosAlmoco,
       DATEDIFF(MINUTE, @entrada, @saida) - DATEDIFF(MINUTE, @almoco_inicio, @almoco_fim) AS MinutosTrabalhados,
       CONVERT(TIME, DATEADD(MINUTE, 
                            DATEDIFF(MINUTE, @entrada, @saida) - DATEDIFF(MINUTE, @almoco_inicio, @almoco_fim), 
                            0)) AS HorasTrabalhadas;

-- =====================================================
-- 4. FORMATAÇÃO DE DATAS EM DIFERENTES FORMATOS
-- =====================================================

-- Exemplo 1: Demonstração de diferentes formatos de conversão
DECLARE @hoje DATETIME = GETDATE();

-- Formatos mais comuns
SELECT @hoje AS DataOriginal,
       CONVERT(VARCHAR(10), @hoje, 103) AS [DD/MM/YYYY],
       CONVERT(VARCHAR(10), @hoje, 101) AS [MM/DD/YYYY],
       CONVERT(VARCHAR(10), @hoje, 102) AS [YYYY.MM.DD],
       CONVERT(VARCHAR(19), @hoje, 120) AS [YYYY-MM-DD HH:MM:SS],
       CONVERT(VARCHAR(16), @hoje, 121) AS [YYYY-MM-DD HH:MM:SS.mmm],
       FORMAT(@hoje, 'dd/MM/yyyy') AS FormatoBrasileiro,
       FORMAT(@hoje, 'yyyy-MM-dd HH:mm:ss') AS FormatoISO;

-- Exemplo 2: Loop para mostrar todos os formatos disponíveis
DECLARE @inicio INT = 1;
DECLARE @termino INT = 25; -- Limitando para os mais comuns
DECLARE @data_teste DATETIME = GETDATE();

CREATE TABLE #FormatacoesData (
    Codigo INT,
    Formato VARCHAR(50),
    Exemplo VARCHAR(50)
);

WHILE (@inicio <= @termino)
BEGIN
    INSERT INTO #FormatacoesData
    SELECT @inicio,
           CASE @inicio
               WHEN 1 THEN 'MM/DD/YY'
               WHEN 2 THEN 'YY.MM.DD'
               WHEN 3 THEN 'DD/MM/YY'
               WHEN 4 THEN 'DD.MM.YY'
               WHEN 5 THEN 'DD-MM-YY'
               WHEN 6 THEN 'DD MON YY'
               WHEN 7 THEN 'MON DD, YY'
               WHEN 8 THEN 'HH:MM:SS'
               WHEN 9 THEN 'MON DD YYYY HH:MM:SS:mmmAM/PM'
               WHEN 10 THEN 'MM-DD-YY'
               WHEN 11 THEN 'YY/MM/DD'
               WHEN 12 THEN 'YYMMDD'
               WHEN 13 THEN 'DD MON YYYY HH:MM:SS:mmm'
               WHEN 14 THEN 'HH:MM:SS:mmm'
               WHEN 20 THEN 'YYYY-MM-DD HH:MM:SS'
               WHEN 21 THEN 'YYYY-MM-DD HH:MM:SS.mmm'
               WHEN 23 THEN 'YYYY-MM-DD'
               WHEN 24 THEN 'HH:MM:SS'
               WHEN 25 THEN 'YYYY-MM-DD HH:MM:SS.mmm'
               ELSE 'Outros'
           END,
           TRY_CONVERT(VARCHAR(30), @data_teste, @inicio);
    
    SET @inicio += 1;
END;

SELECT * FROM #FormatacoesData WHERE Exemplo IS NOT NULL;
DROP TABLE #FormatacoesData;

-- =====================================================
-- 5. DIVISÃO DE UM MÊS EM SEMANAS
-- =====================================================

-- Exemplo 1: Dividir período em semanas (versão simplificada)
DECLARE @startDate DATETIME = '11/01/2024';
DECLARE @endDate DATETIME = '11/30/2024';
DECLARE @WEEKCOUNT INT;

SELECT @WEEKCOUNT = DATEDIFF(WEEK, @startDate, @endDate);

WITH CTESemanas AS (
    -- Primeira semana
    SELECT 1 AS NumeroSemana,
           DATEADD(DAY, -(DATEPART(WEEKDAY, @startDate) - 1), @startDate) AS InicioSemana,
           DATEADD(DAY, 7 - DATEPART(WEEKDAY, @startDate), @startDate) AS FimSemana
    
    UNION ALL
    
    -- Semanas subsequentes
    SELECT NumeroSemana + 1,
           DATEADD(DAY, 1, FimSemana) AS InicioSemana,
           DATEADD(DAY, 7, FimSemana) AS FimSemana
    FROM CTESemanas
    WHERE NumeroSemana < @WEEKCOUNT + 1
)
SELECT NumeroSemana,
       InicioSemana,
       CASE 
           WHEN FimSemana > @endDate THEN @endDate
           ELSE FimSemana
       END AS FimSemana,
       DATEDIFF(DAY, InicioSemana, 
                CASE 
                    WHEN FimSemana > @endDate THEN @endDate
                    ELSE FimSemana
                END) + 1 AS DiasSemana
FROM CTESemanas
WHERE InicioSemana <= @endDate;

-- Exemplo 2: Dividir mês em semanas com informações detalhadas
DECLARE @mes INT = 11;
DECLARE @ano INT = 2024;
DECLARE @primeiro_dia DATETIME = DATEFROMPARTS(@ano, @mes, 1);
DECLARE @ultimo_dia DATETIME = EOMONTH(@primeiro_dia);

WITH CTE_Calendario AS (
    SELECT @primeiro_dia AS Data
    UNION ALL
    SELECT DATEADD(DAY, 1, Data)
    FROM CTE_Calendario
    WHERE Data < @ultimo_dia
),
CTE_Semanas AS (
    SELECT Data,
           DATEPART(WEEKDAY, Data) AS DiaSemana,
           DATENAME(WEEKDAY, Data) AS NomeDiaSemana,
           DATEPART(WEEK, Data) - DATEPART(WEEK, @primeiro_dia) + 1 AS NumeroSemana
    FROM CTE_Calendario
)
SELECT NumeroSemana,
       MIN(Data) AS InicioSemana,
       MAX(Data) AS FimSemana,
       COUNT(*) AS DiasSemana,
       STRING_AGG(CAST(DAY(Data) AS VARCHAR(2)), ', ') AS DiasMes
FROM CTE_Semanas
GROUP BY NumeroSemana
ORDER BY NumeroSemana;

-- =====================================================
-- 6. FUNÇÕES ÚTEIS PARA TRABALHO COM DATAS
-- =====================================================

-- Exemplo 1: Primeiro e último dia do mês
SELECT GETDATE() AS DataAtual,
       DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1) AS PrimeiroDiaMes,
       EOMONTH(GETDATE()) AS UltimoDiaMes,
       EOMONTH(GETDATE(), -1) AS UltimoDiaMesAnterior,
       EOMONTH(GETDATE(), 1) AS UltimoDiaProximoMes;

-- Exemplo 2: Cálculos de idade
DECLARE @data_nascimento DATE = '1990-05-15';

SELECT @data_nascimento AS DataNascimento,
       DATEDIFF(YEAR, @data_nascimento, GETDATE()) AS IdadeAproximada,
       DATEDIFF(YEAR, @data_nascimento, GETDATE()) - 
       CASE 
           WHEN MONTH(@data_nascimento) > MONTH(GETDATE()) OR 
                (MONTH(@data_nascimento) = MONTH(GETDATE()) AND DAY(@data_nascimento) > DAY(GETDATE()))
           THEN 1 
           ELSE 0 
       END AS IdadeExata;

-- Exemplo 3: Dias úteis entre duas datas
DECLARE @data_inicio DATE = '2024-11-01';
DECLARE @data_fim DATE = '2024-11-30';

WITH CTE_Dias AS (
    SELECT @data_inicio AS Data
    UNION ALL
    SELECT DATEADD(DAY, 1, Data)
    FROM CTE_Dias
    WHERE Data < @data_fim
)
SELECT COUNT(*) AS TotalDias,
       SUM(CASE WHEN DATEPART(WEEKDAY, Data) NOT IN (1, 7) THEN 1 ELSE 0 END) AS DiasUteis,
       SUM(CASE WHEN DATEPART(WEEKDAY, Data) IN (1, 7) THEN 1 ELSE 0 END) AS FinsDeSemanaSELECT COUNT(*) AS TotalDias,
       SUM(CASE WHEN DATEPART(WEEKDAY, Data) NOT IN (1, 7) THEN 1 ELSE 0 END) AS DiasUteis,
       SUM(CASE WHEN DATEPART(WEEKDAY, Data) IN (1, 7) THEN 1 ELSE 0 END) AS FinsDeSemana
FROM CTE_Dias;

-- =====================================================
-- 7. EXERCÍCIOS PRÁTICOS
-- =====================================================

/*
EXERCÍCIO 1:
Crie uma consulta que mostre:
- Data atual
- Primeiro dia do ano atual
- Último dia do ano atual
- Quantos dias faltam para o fim do ano

EXERCÍCIO 2:
Calcule a diferença em anos, meses e dias entre duas datas:
- Data 1: 15/03/2020
- Data 2: 22/11/2024

EXERCÍCIO 3:
Crie uma função que converta segundos em formato HH:MM:SS
Teste com: 3661 segundos (deve retornar 01:01:01)

EXERCÍCIO 4:
Gere um relatório mostrando todos os domingos do mês atual

EXERCÍCIO 5:
Calcule quantas horas de trabalho existem entre duas datas,
considerando apenas dias úteis (segunda a sexta) e
8 horas por dia.
*/

-- =====================================================
-- SOLUÇÕES DOS EXERCÍCIOS
-- =====================================================

-- SOLUÇÃO 1:
/*
SELECT GETDATE() AS DataAtual,
       DATEFROMPARTS(YEAR(GETDATE()), 1, 1) AS PrimeiroDiaAno,
       DATEFROMPARTS(YEAR(GETDATE()), 12, 31) AS UltimoDiaAno,
       DATEDIFF(DAY, GETDATE(), DATEFROMPARTS(YEAR(GETDATE()), 12, 31)) AS DiasParaFimAno;
*/

-- SOLUÇÃO 2:
/*
DECLARE @data1 DATE = '2020-03-15';
DECLARE @data2 DATE = '2024-11-22';

SELECT DATEDIFF(YEAR, @data1, @data2) AS Anos,
       DATEDIFF(MONTH, @data1, @data2) % 12 AS Meses,
       DAY(@data2) - DAY(@data1) AS Dias;
*/

-- SOLUÇÃO 3:
/*
DECLARE @segundos INT = 3661;
SELECT CONVERT(VARCHAR(8), DATEADD(SECOND, @segundos, 0), 108) AS TempoFormatado;
*/

-- SOLUÇÃO 4:
/*
DECLARE @primeiro_dia_mes DATE = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
DECLARE @ultimo_dia_mes DATE = EOMONTH(GETDATE());

WITH CTE_Dias AS (
    SELECT @primeiro_dia_mes AS Data
    UNION ALL
    SELECT DATEADD(DAY, 1, Data)
    FROM CTE_Dias
    WHERE Data < @ultimo_dia_mes
)
SELECT Data, DATENAME(WEEKDAY, Data) AS DiaSemana
FROM CTE_Dias
WHERE DATEPART(WEEKDAY, Data) = 1; -- Domingo
*/

-- SOLUÇÃO 5:
/*
DECLARE @inicio DATE = '2024-11-01';
DECLARE @fim DATE = '2024-11-30';

WITH CTE_DiasUteis AS (
    SELECT @inicio AS Data
    UNION ALL
    SELECT DATEADD(DAY, 1, Data)
    FROM CTE_DiasUteis
    WHERE Data < @fim
)
SELECT COUNT(*) AS DiasUteis,
       COUNT(*) * 8 AS HorasTrabalhadas
FROM CTE_DiasUteis
WHERE DATEPART(WEEKDAY, Data) BETWEEN 2 AND 6; -- Segunda a Sexta
*/