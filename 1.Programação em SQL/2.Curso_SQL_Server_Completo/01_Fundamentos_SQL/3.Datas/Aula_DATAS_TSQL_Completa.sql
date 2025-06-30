/*
═══════════════════════════════════════════════════════════════
                    AULA COMPLETA - MANIPULAÇÃO DE DATAS
                        SQL Server T-SQL
═══════════════════════════════════════════════════════════════

Autor: Wesley Neves
Data: 2024
Descrição: Aula completa sobre manipulação de datas em T-SQL,
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
-- 1. TIPOS DE DADOS DE DATA E HORA
-- ═══════════════════════════════════════════════════════════════

/*
Tipos de dados de data/hora no SQL Server:

1. DATE - Apenas data (YYYY-MM-DD) - 3 bytes
2. TIME - Apenas hora (HH:MM:SS.nnnnnnn) - 3-5 bytes
3. DATETIME - Data e hora (1753-9999) - 8 bytes
4. DATETIME2 - Data e hora com maior precisão (0001-9999) - 6-8 bytes
5. SMALLDATETIME - Data e hora com menor precisão - 4 bytes
6. DATETIMEOFFSET - Data, hora e fuso horário - 10 bytes
*/

-- Exemplos de declaração de variáveis com diferentes tipos
DECLARE @DataAtual DATE = GETDATE();
DECLARE @HoraAtual TIME = GETDATE();
DECLARE @DataHoraAtual DATETIME = GETDATE();
DECLARE @DataHora2 DATETIME2 = GETDATE();
DECLARE @DataHoraOffset DATETIMEOFFSET = GETDATE();

-- Exibindo os valores
SELECT 
    @DataAtual AS 'DATE',
    @HoraAtual AS 'TIME',
    @DataHoraAtual AS 'DATETIME',
    @DataHora2 AS 'DATETIME2',
    @DataHoraOffset AS 'DATETIMEOFFSET';

-- ═══════════════════════════════════════════════════════════════
-- 2. FUNÇÕES BÁSICAS DE DATA E HORA
-- ═══════════════════════════════════════════════════════════════

-- GETDATE() - Retorna a data e hora atual do sistema
SELECT GETDATE() AS DataHoraAtual;

-- GETUTCDATE() - Retorna a data e hora UTC
SELECT GETUTCDATE() AS DataHoraUTC;

-- SYSDATETIME() - Retorna data/hora com maior precisão
SELECT SYSDATETIME() AS DataHoraPrecisa;

-- CURRENT_TIMESTAMP - Equivalente ao GETDATE()
SELECT CURRENT_TIMESTAMP AS DataHoraAtual2;

-- ═══════════════════════════════════════════════════════════════
-- 3. EXTRAINDO PARTES DE UMA DATA
-- ═══════════════════════════════════════════════════════════════

DECLARE @MinhaData DATETIME = '2024-12-15 14:30:45.123';

-- Usando DATEPART
SELECT 
    DATEPART(YEAR, @MinhaData) AS Ano,
    DATEPART(MONTH, @MinhaData) AS Mes,
    DATEPART(DAY, @MinhaData) AS Dia,
    DATEPART(HOUR, @MinhaData) AS Hora,
    DATEPART(MINUTE, @MinhaData) AS Minuto,
    DATEPART(SECOND, @MinhaData) AS Segundo,
    DATEPART(MILLISECOND, @MinhaData) AS Milissegundo,
    DATEPART(WEEKDAY, @MinhaData) AS DiaSemana,
    DATEPART(WEEK, @MinhaData) AS SemanaAno,
    DATEPART(QUARTER, @MinhaData) AS Trimestre;

-- Usando funções específicas (mais legíveis)
SELECT 
    YEAR(@MinhaData) AS Ano,
    MONTH(@MinhaData) AS Mes,
    DAY(@MinhaData) AS Dia;

-- DATENAME - Retorna o nome da parte da data
SELECT 
    DATENAME(MONTH, @MinhaData) AS NomeMes,
    DATENAME(WEEKDAY, @MinhaData) AS NomeDiaSemana,
    DATENAME(QUARTER, @MinhaData) AS NomeTrimestre;

-- ═══════════════════════════════════════════════════════════════
-- 4. ADICIONANDO E SUBTRAINDO DATAS - DATEADD
-- ═══════════════════════════════════════════════════════════════

-- DATEADD(parte, valor, data) - Adiciona um valor a uma parte da data
DECLARE @DataBase DATETIME = '2024-01-15 10:30:00';

SELECT 
    @DataBase AS DataOriginal,
    DATEADD(YEAR, 1, @DataBase) AS MaisUmAno,
    DATEADD(MONTH, 3, @DataBase) AS MaisTresMeses,
    DATEADD(DAY, 15, @DataBase) AS MaisQuinzeDias,
    DATEADD(HOUR, 5, @DataBase) AS MaisCincoHoras,
    DATEADD(MINUTE, 30, @DataBase) AS MaisTrintaMinutos,
    DATEADD(SECOND, 45, @DataBase) AS MaisQuarentaCincoSegundos;

-- Subtraindo (usando valores negativos)
SELECT 
    @DataBase AS DataOriginal,
    DATEADD(YEAR, -1, @DataBase) AS MenosUmAno,
    DATEADD(MONTH, -6, @DataBase) AS MenosSeiseMeses,
    DATEADD(DAY, -30, @DataBase) AS MenosTrintaDias;

-- Exemplos práticos
SELECT 
    GETDATE() AS Hoje,
    DATEADD(DAY, -30, GETDATE()) AS UltimosTrintaDias,
    DATEADD(MONTH, 1, GETDATE()) AS ProximoMes,
    DATEADD(YEAR, 1, GETDATE()) AS ProximoAno;

-- ═══════════════════════════════════════════════════════════════
-- 5. CALCULANDO DIFERENÇAS ENTRE DATAS - DATEDIFF
-- ═══════════════════════════════════════════════════════════════

-- DATEDIFF(parte, data_inicial, data_final) - Calcula a diferença entre duas datas
DECLARE @DataInicio DATETIME = '2024-01-01';
DECLARE @DataFim DATETIME = '2024-12-31';

SELECT 
    @DataInicio AS DataInicio,
    @DataFim AS DataFim,
    DATEDIFF(YEAR, @DataInicio, @DataFim) AS DiferencaAnos,
    DATEDIFF(MONTH, @DataInicio, @DataFim) AS DiferencaMeses,
    DATEDIFF(DAY, @DataInicio, @DataFim) AS DiferencaDias,
    DATEDIFF(HOUR, @DataInicio, @DataFim) AS DiferencaHoras,
    DATEDIFF(MINUTE, @DataInicio, @DataFim) AS DiferencaMinutos;

-- Calculando idade
DECLARE @DataNascimento DATE = '1990-05-15';
SELECT 
    @DataNascimento AS DataNascimento,
    DATEDIFF(YEAR, @DataNascimento, GETDATE()) AS Idade;

-- Exemplo prático: Cálculo com TIME (baseado no arquivo existente)
DECLARE @Campo1 VARCHAR(5) = '17:00';
DECLARE @Campo2 VARCHAR(5) = '17:10';

-- Calculando diferença entre horários e convertendo para formato legível
SELECT 
    @Campo1 AS HorarioInicio,
    @Campo2 AS HorarioFim,
    CONVERT(VARCHAR(5), 
        DATEADD(SECOND, 
            DATEDIFF(SECOND, CAST(@Campo1 AS TIME(0)), CAST(@Campo2 AS TIME(0))), 
            0
        ), 
        108
    ) AS DiferencaTempo;

-- ═══════════════════════════════════════════════════════════════
-- 6. CONVERSÃO DE MILISSEGUNDOS PARA TEMPO
-- ═══════════════════════════════════════════════════════════════

-- Baseado no arquivo "1.Convert de milisegundos para segundos.sql"
-- Convertendo milissegundos para formato de tempo legível
DECLARE @Milissegundos INT = 15168; -- 15.168 segundos

SELECT 
    @Milissegundos AS Milissegundos,
    CONVERT(TIME, DATEADD(ms, @Milissegundos, 0)) AS [Tempo Decorrido em Segundos];

-- Exemplos com diferentes valores
SELECT 
    3600000 AS Milissegundos, -- 1 hora
    CONVERT(TIME, DATEADD(ms, 3600000, 0)) AS TempoFormatado
UNION ALL
SELECT 
    90000 AS Milissegundos, -- 1 minuto e 30 segundos
    CONVERT(TIME, DATEADD(ms, 90000, 0)) AS TempoFormatado
UNION ALL
SELECT 
    5500 AS Milissegundos, -- 5.5 segundos
    CONVERT(TIME, DATEADD(ms, 5500, 0)) AS TempoFormatado;

-- ═══════════════════════════════════════════════════════════════
-- 7. FORMATAÇÃO DE DATAS - CONVERT E FORMAT
-- ═══════════════════════════════════════════════════════════════

-- Baseado no arquivo "ConvertDateTimeDiferentesFormatos.sql"
-- Demonstrando diferentes formatos de conversão
DECLARE @DataExemplo DATETIME = GETDATE();

-- Formatos mais comuns usando CONVERT
SELECT 
    @DataExemplo AS DataOriginal,
    CONVERT(VARCHAR(10), @DataExemplo, 103) AS 'DD/MM/YYYY',
    CONVERT(VARCHAR(10), @DataExemplo, 101) AS 'MM/DD/YYYY',
    CONVERT(VARCHAR(10), @DataExemplo, 112) AS 'YYYYMMDD',
    CONVERT(VARCHAR(19), @DataExemplo, 120) AS 'YYYY-MM-DD HH:MI:SS',
    CONVERT(VARCHAR(16), @DataExemplo, 121) AS 'YYYY-MM-DD HH:MI:SS.mmm';

-- Demonstração de todos os formatos (adaptado do arquivo existente)
DECLARE @Contador INT = 1;
DECLARE @Limite INT = 25; -- Limitando para os formatos mais úteis
DECLARE @Hoje DATETIME = GETDATE();

-- Criando tabela temporária para armazenar os resultados
CREATE TABLE #FormatosData (
    Codigo INT,
    Formato VARCHAR(50),
    Exemplo VARCHAR(50)
);

-- Loop para testar diferentes formatos
WHILE (@Contador <= @Limite)
BEGIN
    INSERT INTO #FormatosData (Codigo, Formato, Exemplo)
    SELECT 
        @Contador,
        CASE @Contador
            WHEN 1 THEN 'MM/DD/YY'
            WHEN 2 THEN 'YY.MM.DD'
            WHEN 3 THEN 'DD/MM/YY'
            WHEN 4 THEN 'DD.MM.YY'
            WHEN 5 THEN 'DD-MM-YY'
            WHEN 6 THEN 'DD MON YY'
            WHEN 7 THEN 'MON DD, YY'
            WHEN 8 THEN 'HH:MI:SS'
            WHEN 9 THEN 'MON DD YYYY HH:MI:SS:mmmAM'
            WHEN 10 THEN 'MM-DD-YY'
            WHEN 11 THEN 'YY/MM/DD'
            WHEN 12 THEN 'YYMMDD'
            WHEN 13 THEN 'DD MON YYYY HH:MI:SS:mmm'
            WHEN 14 THEN 'HH:MI:SS:mmm'
            WHEN 20 THEN 'YYYY-MM-DD HH:MI:SS'
            WHEN 21 THEN 'YYYY-MM-DD HH:MI:SS.mmm'
            WHEN 23 THEN 'YYYY-MM-DD'
            ELSE 'Outros formatos'
        END,
        TRY_CONVERT(VARCHAR(30), @Hoje, @Contador);
    
    SET @Contador += 1;
END

-- Exibindo os resultados
SELECT Codigo, Formato, Exemplo
FROM #FormatosData
WHERE Exemplo IS NOT NULL
ORDER BY Codigo;

-- Limpando tabela temporária
DROP TABLE #FormatosData;

-- Usando FORMAT (SQL Server 2012+) - Mais flexível
SELECT 
    FORMAT(@DataExemplo, 'dd/MM/yyyy') AS 'Formato Brasileiro',
    FORMAT(@DataExemplo, 'MM/dd/yyyy') AS 'Formato Americano',
    FORMAT(@DataExemplo, 'yyyy-MM-dd') AS 'Formato ISO',
    FORMAT(@DataExemplo, 'dddd, dd MMMM yyyy') AS 'Formato Extenso',
    FORMAT(@DataExemplo, 'HH:mm:ss') AS 'Apenas Hora',
    FORMAT(@DataExemplo, 'dd/MM/yyyy HH:mm:ss') AS 'Data e Hora Completa';

-- ═══════════════════════════════════════════════════════════════
-- 8. TRABALHANDO COM PERÍODOS E INTERVALOS
-- ═══════════════════════════════════════════════════════════════

-- Primeiro e último dia do mês
DECLARE @QualquerData DATE = '2024-06-15';

SELECT 
    @QualquerData AS DataOriginal,
    DATEFROMPARTS(YEAR(@QualquerData), MONTH(@QualquerData), 1) AS PrimeiroDiaMes,
    EOMONTH(@QualquerData) AS UltimoDiaMes;

-- Primeiro e último dia do ano
SELECT 
    @QualquerData AS DataOriginal,
    DATEFROMPARTS(YEAR(@QualquerData), 1, 1) AS PrimeiroDiaAno,
    DATEFROMPARTS(YEAR(@QualquerData), 12, 31) AS UltimoDiaAno;

-- Primeiro dia da semana (segunda-feira)
SELECT 
    @QualquerData AS DataOriginal,
    DATEADD(DAY, 1 - DATEPART(WEEKDAY, @QualquerData), @QualquerData) AS PrimeiroDiaSemana;

-- ═══════════════════════════════════════════════════════════════
-- 9. DIVIDINDO PERÍODOS EM SEMANAS (TÉCNICA AVANÇADA)
-- ═══════════════════════════════════════════════════════════════

-- Baseado no arquivo "3.DivideUmMesEmSemanas.sql"
-- Técnica para dividir um período em semanas ou meses
DECLARE @DataInicioPeriodo DATETIME = '2024-09-01';
DECLARE @DataFimPeriodo DATETIME = '2024-11-30';
DECLARE @ContadorSemanas INT;
DECLARE @NumeroMagico INT;

-- Calculando quantas semanas existem no período
SELECT @ContadorSemanas = DATEDIFF(WEEK, @DataInicioPeriodo, @DataFimPeriodo);

-- Determinando se vamos dividir por semanas ou meses
SELECT @NumeroMagico = CASE 
                           WHEN @ContadorSemanas < 8 THEN @ContadorSemanas
                           ELSE (MONTH(@DataFimPeriodo) - MONTH(@DataInicioPeriodo)) + 1
                       END;

-- CTE recursiva para gerar os períodos
WITH DivisaoPeriodos AS (
    -- Caso base: primeiro período
    SELECT 
        1 AS NumeroPeriodo,
        CASE 
            WHEN @ContadorSemanas < 8 THEN 
                DATEADD(DAY, -(DATEPART(WEEKDAY, @DataInicioPeriodo)) + 1, @DataInicioPeriodo)
            ELSE 
                DATEADD(DAY, -(DAY(@DataInicioPeriodo) - 1), @DataInicioPeriodo)
        END AS InicioSemana,
        CASE 
            WHEN @ContadorSemanas < 8 THEN 
                DATEADD(DAY, 7 - (DATEPART(WEEKDAY, @DataInicioPeriodo)) + 1, @DataInicioPeriodo)
            ELSE 
                DATEADD(SECOND, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @DataInicioPeriodo) + 1, 0))
        END AS FimSemana
    
    UNION ALL
    
    -- Caso recursivo: próximos períodos
    SELECT 
        dp.NumeroPeriodo + 1,
        CASE 
            WHEN @ContadorSemanas < 8 THEN 
                DATEADD(DAY, 
                    -(DATEPART(WEEKDAY, @DataInicioPeriodo + (7 * (dp.NumeroPeriodo + 1)))) + 2,
                    @DataInicioPeriodo + (7 * (dp.NumeroPeriodo + 1))
                )
            ELSE 
                DATEADD(DAY, 
                    -(DAY(@DataInicioPeriodo + (30 * (dp.NumeroPeriodo + 1))) - 1),
                    @DataInicioPeriodo + (30 * (dp.NumeroPeriodo + 1))
                )
        END,
        CASE 
            WHEN @ContadorSemanas < 8 THEN 
                DATEADD(DAY, 
                    7 - (DATEPART(WEEKDAY, @DataInicioPeriodo + (7 * (dp.NumeroPeriodo + 1)))) + 1,
                    @DataInicioPeriodo + (7 * (dp.NumeroPeriodo + 1))
                )
            ELSE 
                DATEADD(SECOND, -1,
                    DATEADD(MONTH, 
                        DATEDIFF(MONTH, 0, @DataInicioPeriodo + (30 * (dp.NumeroPeriodo + 1))) + 1, 
                        0
                    )
                )
        END
    FROM DivisaoPeriodos dp
    WHERE (dp.NumeroPeriodo + 1) <= @NumeroMagico
)
SELECT 
    NumeroPeriodo,
    FORMAT(InicioSemana, 'dd/MM/yyyy') AS InicioSemana,
    FORMAT(FimSemana, 'dd/MM/yyyy') AS FimSemana,
    DATEDIFF(DAY, InicioSemana, FimSemana) + 1 AS DiasPeriodo
FROM DivisaoPeriodos
ORDER BY NumeroPeriodo;

-- ═══════════════════════════════════════════════════════════════
-- 10. FUNÇÕES AVANÇADAS DE DATA
-- ═══════════════════════════════════════════════════════════════

-- DATEFROMPARTS - Constrói uma data a partir de partes
SELECT 
    DATEFROMPARTS(2024, 12, 25) AS DataNatal,
    TIMEFROMPARTS(14, 30, 0, 0, 0) AS HoraAlmoco,
    DATETIMEFROMPARTS(2024, 12, 25, 14, 30, 0, 0) AS DataHoraNatal;

-- EOMONTH - Último dia do mês
SELECT 
    EOMONTH(GETDATE()) AS UltimoDiaMesAtual,
    EOMONTH(GETDATE(), 1) AS UltimoDiaProximoMes,
    EOMONTH(GETDATE(), -1) AS UltimoDiaMesAnterior;

-- ISDATE - Verifica se uma string é uma data válida
SELECT 
    ISDATE('2024-12-25') AS DataValida1,
    ISDATE('2024-13-25') AS DataInvalida1,
    ISDATE('25/12/2024') AS DataValida2,
    ISDATE('abc') AS DataInvalida2;

-- ═══════════════════════════════════════════════════════════════
-- 11. TRABALHANDO COM FUSOS HORÁRIOS
-- ═══════════════════════════════════════════════════════════════

-- DATETIMEOFFSET - Trabalhando com fusos horários
DECLARE @DataComFuso DATETIMEOFFSET = '2024-12-25 14:30:00 -03:00';

SELECT 
    @DataComFuso AS DataOriginal,
    SWITCHOFFSET(@DataComFuso, '+00:00') AS DataUTC,
    SWITCHOFFSET(@DataComFuso, '+09:00') AS DataToquio,
    SWITCHOFFSET(@DataComFuso, '-05:00') AS DataNovaYork;

-- Convertendo para UTC
SELECT 
    GETDATE() AS HoraLocal,
    GETUTCDATE() AS HoraUTC,
    TODATETIMEOFFSET(GETDATE(), '-03:00') AS HoraComFuso;

-- ═══════════════════════════════════════════════════════════════
-- 12. CONSULTAS PRÁTICAS COM DATAS
-- ═══════════════════════════════════════════════════════════════

-- Vendas do mês atual
SELECT 
    VendaID,
    DataVenda,
    ValorTotal
FROM Vendas
WHERE YEAR(DataVenda) = YEAR(GETDATE())
  AND MONTH(DataVenda) = MONTH(GETDATE());

-- Vendas dos últimos 30 dias
SELECT 
    VendaID,
    DataVenda,
    ValorTotal,
    DATEDIFF(DAY, DataVenda, GETDATE()) AS DiasAtras
FROM Vendas
WHERE DataVenda >= DATEADD(DAY, -30, GETDATE())
ORDER BY DataVenda DESC;

-- Vendas por trimestre
SELECT 
    YEAR(DataVenda) AS Ano,
    DATEPART(QUARTER, DataVenda) AS Trimestre,
    COUNT(*) AS QuantidadeVendas,
    SUM(ValorTotal) AS TotalVendas
FROM Vendas
GROUP BY YEAR(DataVenda), DATEPART(QUARTER, DataVenda)
ORDER BY Ano, Trimestre;

-- Vendas por dia da semana
SELECT 
    DATENAME(WEEKDAY, DataVenda) AS DiaSemana,
    COUNT(*) AS QuantidadeVendas,
    AVG(ValorTotal) AS MediaVendas
FROM Vendas
GROUP BY DATEPART(WEEKDAY, DataVenda), DATENAME(WEEKDAY, DataVenda)
ORDER BY DATEPART(WEEKDAY, DataVenda);

-- ═══════════════════════════════════════════════════════════════
-- 13. PERFORMANCE COM DATAS
-- ═══════════════════════════════════════════════════════════════

-- ❌ EVITE: Funções em colunas indexadas
-- SELECT * FROM Vendas WHERE YEAR(DataVenda) = 2024;

-- ✅ PREFIRA: Intervalos de data
SELECT VendaID, DataVenda, ValorTotal
FROM Vendas
WHERE DataVenda >= '2024-01-01' 
  AND DataVenda < '2025-01-01';

-- ❌ EVITE: Conversões desnecessárias
-- SELECT * FROM Vendas WHERE CONVERT(DATE, DataVenda) = '2024-12-25';

-- ✅ PREFIRA: Intervalos específicos
SELECT VendaID, DataVenda, ValorTotal
FROM Vendas
WHERE DataVenda >= '2024-12-25 00:00:00'
  AND DataVenda < '2024-12-26 00:00:00';

-- ═══════════════════════════════════════════════════════════════
-- 14. VALIDAÇÃO E TRATAMENTO DE ERROS COM DATAS
-- ═══════════════════════════════════════════════════════════════

-- TRY_CONVERT - Conversão segura
SELECT 
    TRY_CONVERT(DATE, '2024-12-25') AS DataValida,
    TRY_CONVERT(DATE, '2024-13-25') AS DataInvalida,
    TRY_CONVERT(DATE, 'abc') AS TextoInvalido;

-- Validação antes de conversão
DECLARE @TextoData VARCHAR(20) = '25/12/2024';

IF ISDATE(@TextoData) = 1
BEGIN
    SELECT CONVERT(DATE, @TextoData) AS DataConvertida;
END
ELSE
BEGIN
    SELECT 'Data inválida: ' + @TextoData AS Erro;
END

-- ═══════════════════════════════════════════════════════════════
-- 15. EXERCÍCIOS PRÁTICOS
-- ═══════════════════════════════════════════════════════════════

-- Exercício 1: Calcular a idade de todos os clientes
-- (Assumindo que existe um campo DataNascimento na tabela Clientes)
/*
SELECT 
    NomeCliente,
    DataNascimento,
    DATEDIFF(YEAR, DataNascimento, GETDATE()) AS Idade,
    CASE 
        WHEN DATEDIFF(YEAR, DataNascimento, GETDATE()) >= 18 THEN 'Maior de idade'
        ELSE 'Menor de idade'
    END AS Categoria
FROM Clientes
WHERE DataNascimento IS NOT NULL;
*/

-- Exercício 2: Vendas por período específico com formatação
SELECT 
    FORMAT(DataVenda, 'MMMM yyyy') AS MesAno,
    COUNT(*) AS QuantidadeVendas,
    FORMAT(SUM(ValorTotal), 'C', 'pt-BR') AS TotalFormatado
FROM Vendas
WHERE DataVenda >= DATEADD(MONTH, -6, GETDATE())
GROUP BY YEAR(DataVenda), MONTH(DataVenda), FORMAT(DataVenda, 'MMMM yyyy')
ORDER BY YEAR(DataVenda), MONTH(DataVenda);

-- Exercício 3: Tempo decorrido desde a última venda
SELECT TOP 10
    VendaID,
    DataVenda,
    FORMAT(DataVenda, 'dd/MM/yyyy HH:mm') AS DataFormatada,
    DATEDIFF(DAY, DataVenda, GETDATE()) AS DiasAtras,
    CASE 
        WHEN DATEDIFF(DAY, DataVenda, GETDATE()) = 0 THEN 'Hoje'
        WHEN DATEDIFF(DAY, DataVenda, GETDATE()) = 1 THEN 'Ontem'
        WHEN DATEDIFF(DAY, DataVenda, GETDATE()) <= 7 THEN 'Esta semana'
        WHEN DATEDIFF(DAY, DataVenda, GETDATE()) <= 30 THEN 'Este mês'
        ELSE 'Mais de um mês'
    END AS TempoRelativo
FROM Vendas
ORDER BY DataVenda DESC;

-- ═══════════════════════════════════════════════════════════════
-- 16. DICAS IMPORTANTES E BOAS PRÁTICAS
-- ═══════════════════════════════════════════════════════════════

/*
DICAS DE BOAS PRÁTICAS COM DATAS:

1. SEMPRE use o formato ISO (YYYY-MM-DD) para literais de data
2. Evite funções em colunas indexadas no WHERE
3. Use DATETIME2 ao invés de DATETIME para novos projetos
4. Considere fusos horários em aplicações globais
5. Valide datas antes de fazer conversões
6. Use TRY_CONVERT para conversões seguras
7. Prefira DATEADD/DATEDIFF para cálculos de data
8. Documente o fuso horário usado em suas aplicações
9. Teste sempre com dados de borda (anos bissextos, mudanças de horário)
10. Use FORMAT para apresentação, não para cálculos

FORMATOS COMUNS DE CONVERT:
- 103: DD/MM/YYYY (Brasileiro)
- 101: MM/DD/YYYY (Americano)
- 112: YYYYMMDD (ISO sem separadores)
- 120: YYYY-MM-DD HH:MI:SS (ISO completo)
- 121: YYYY-MM-DD HH:MI:SS.mmm (ISO com milissegundos)

PARTES DE DATA PARA DATEPART/DATEADD:
- YEAR, YYYY, YY: Ano
- QUARTER, QQ, Q: Trimestre
- MONTH, MM, M: Mês
- DAYOFYEAR, DY, Y: Dia do ano
- DAY, DD, D: Dia
- WEEK, WK, WW: Semana
- WEEKDAY, DW: Dia da semana
- HOUR, HH: Hora
- MINUTE, MI, N: Minuto
- SECOND, SS, S: Segundo
- MILLISECOND, MS: Milissegundo

LEMBRE-SE:
- SQL Server armazena datas internamente em UTC
- DATETIME tem precisão de 3.33ms
- DATETIME2 tem precisão de 100ns
- Sempre considere anos bissextos em cálculos
- Cuidado com mudanças de horário de verão
*/

-- ═══════════════════════════════════════════════════════════════
-- FIM DA AULA
-- ═══════════════════════════════════════════════════════════════

/*
Esta aula cobriu todos os aspectos importantes de manipulação de datas:
- Tipos de dados de data e hora
- Funções básicas (GETDATE, DATEPART, etc.)
- Cálculos com datas (DATEADD, DATEDIFF)
- Conversão de milissegundos para tempo
- Formatação de datas (CONVERT, FORMAT)
- Divisão de períodos em semanas/meses
- Funções avançadas e fusos horários
- Consultas práticas com datas
- Performance e otimização
- Validação e tratamento de erros
- Exercícios práticos

Próximos passos:
- Pratique com os exercícios propostos
- Experimente diferentes formatos de data
- Estude sobre índices em colunas de data
- Aprenda sobre particionamento por data
- Explore funções específicas do seu cenário de uso
*/