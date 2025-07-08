
-- =============================================
-- Stored Procedure: uspLoadDimTempo
-- Descrição: Popula a tabela DimTempo usando CTEs recursivas e MERGE para melhor performance
-- Autor: Sistema BI
-- Data: Criação automática - Versão otimizada com CTE
-- =============================================

CREATE OR ALTER PROCEDURE [Shared].[uspLoadDimTempo]
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Declaração de variáveis
    DECLARE @MinData DATE;
    DECLARE @MaxData DATE;
    DECLARE @TotalRegistros INT = 0;
    DECLARE @RegistrosInseridos INT = 0;
    DECLARE @RegistrosExistentes INT = 0;
    DECLARE @InicioProcessamento DATETIME = GETDATE();
    
    BEGIN TRY
        -- Busca o intervalo de datas da tabela staging
        SELECT 
            @MinData = MIN(DataVigenciaInicial), 
            @MaxData = MAX(DataVigenciaFinal) 
        FROM Staging.ClientesProdutosCIGAM;
        
        -- Adiciona margem de segurança (1 ano antes e 2 anos depois)
        SET @MinData = DATEADD(YEAR, -1, @MinData);
        SET @MaxData = DATEADD(YEAR, 2, @MaxData);
        
        -- Calcula total de dias para processamento
        SET @TotalRegistros = DATEDIFF(DAY, @MinData, @MaxData) + 1;
        
        PRINT 'Iniciando carga otimizada da DimTempo com CTEs recursivas...';
        PRINT 'Período: ' + CONVERT(VARCHAR(10), @MinData, 103) + ' até ' + CONVERT(VARCHAR(10), @MaxData, 103);
        PRINT 'Total de registros a processar: ' + CAST(@TotalRegistros AS VARCHAR(10));
        PRINT '';
        
        -- Cria tabela temporária para armazenar os dados gerados pela CTE
        CREATE TABLE #TempDimTempo (
            DataKey INT NOT NULL,
            Data DATE NOT NULL,
            Ano INT NOT NULL,
            Mes INT NOT NULL,
            Trimestre INT NOT NULL,
            Semestre INT NOT NULL,
            NomeMes VARCHAR(20) NOT NULL,
            DiaSemana INT NOT NULL,
            NomeDiaSemana VARCHAR(20) NOT NULL,
            PRIMARY KEY (DataKey)
        );
        
        PRINT 'Gerando dados com CTE recursiva...';
        
        -- CTE recursiva para gerar todas as datas do intervalo
        WITH CTE_Datas AS (
            -- Âncora: data inicial
            SELECT @MinData AS Data
            
            UNION ALL
            
            -- Recursão: adiciona um dia até atingir a data máxima
            SELECT DATEADD(DAY, 1, Data)
            FROM CTE_Datas
            WHERE Data < @MaxData
        ),
        -- CTE para calcular todos os campos derivados
        CTE_DadosCompletos AS (
            SELECT 
                -- DataKey no formato YYYYMMDD
                YEAR(Data) * 10000 + MONTH(Data) * 100 + DAY(Data) AS DataKey,
                Data,
                YEAR(Data) AS Ano,
                MONTH(Data) AS Mes,
                -- Calcula trimestre
                CASE 
                    WHEN MONTH(Data) IN (1,2,3) THEN 1
                    WHEN MONTH(Data) IN (4,5,6) THEN 2
                    WHEN MONTH(Data) IN (7,8,9) THEN 3
                    ELSE 4
                END AS Trimestre,
                -- Calcula semestre
                CASE 
                    WHEN MONTH(Data) <= 6 THEN 1
                    ELSE 2
                END AS Semestre,
                -- Nome do mês em português
                CASE MONTH(Data)
                    WHEN 1 THEN 'Janeiro'
                    WHEN 2 THEN 'Fevereiro'
                    WHEN 3 THEN 'Março'
                    WHEN 4 THEN 'Abril'
                    WHEN 5 THEN 'Maio'
                    WHEN 6 THEN 'Junho'
                    WHEN 7 THEN 'Julho'
                    WHEN 8 THEN 'Agosto'
                    WHEN 9 THEN 'Setembro'
                    WHEN 10 THEN 'Outubro'
                    WHEN 11 THEN 'Novembro'
                    WHEN 12 THEN 'Dezembro'
                END AS NomeMes,
                DATEPART(WEEKDAY, Data) AS DiaSemana,
                -- Nome do dia da semana em português
                CASE DATEPART(WEEKDAY, Data)
                    WHEN 1 THEN 'Domingo'
                    WHEN 2 THEN 'Segunda-feira'
                    WHEN 3 THEN 'Terça-feira'
                    WHEN 4 THEN 'Quarta-feira'
                    WHEN 5 THEN 'Quinta-feira'
                    WHEN 6 THEN 'Sexta-feira'
                    WHEN 7 THEN 'Sábado'
                END AS NomeDiaSemana
            FROM CTE_Datas
        )
        -- Insere todos os dados na tabela temporária
        INSERT INTO #TempDimTempo (
            DataKey, Data, Ano, Mes, Trimestre, Semestre, 
            NomeMes, DiaSemana, NomeDiaSemana
        )
        SELECT 
            DataKey, Data, Ano, Mes, Trimestre, Semestre, 
            NomeMes, DiaSemana, NomeDiaSemana
        FROM CTE_DadosCompletos
        OPTION (MAXRECURSION 0); -- Remove limite de recursão
        
        PRINT 'Dados gerados na tabela temporária. Executando MERGE...';
        
        -- Usa MERGE para inserir apenas registros que não existem
        MERGE Shared.DimTempo AS Target
        USING #TempDimTempo AS Source
        ON Target.DataKey = Source.DataKey
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (DataKey, Data, Ano, Mes, Trimestre, Semestre, NomeMes, DiaSemana, NomeDiaSemana)
            VALUES (Source.DataKey, Source.Data, Source.Ano, Source.Mes, Source.Trimestre, 
                   Source.Semestre, Source.NomeMes, Source.DiaSemana, Source.NomeDiaSemana);
        
        -- Captura estatísticas do MERGE
        SET @RegistrosInseridos = @@ROWCOUNT;
        SET @RegistrosExistentes = @TotalRegistros - @RegistrosInseridos;
        
        -- Limpa tabela temporária
        DROP TABLE #TempDimTempo;
        
        -- Estatísticas finais
        DECLARE @TempoProcessamento VARCHAR(20) = CONVERT(VARCHAR(20), GETDATE() - @InicioProcessamento, 108);
        
        PRINT '';
        PRINT '=================================================';
        PRINT 'CARGA OTIMIZADA DA DIMTEMPO CONCLUÍDA COM SUCESSO!';
        PRINT '=================================================';
        PRINT 'Total de registros processados: ' + CAST(@TotalRegistros AS VARCHAR(10));
        PRINT 'Registros inseridos (novos): ' + CAST(@RegistrosInseridos AS VARCHAR(10));
        PRINT 'Registros já existentes: ' + CAST(@RegistrosExistentes AS VARCHAR(10));
        PRINT 'Tempo de processamento: ' + @TempoProcessamento;
        PRINT 'Período coberto: ' + CONVERT(VARCHAR(10), @MinData, 103) + ' até ' + CONVERT(VARCHAR(10), @MaxData, 103);
        PRINT 'Método: CTE Recursiva + MERGE (sem duplicatas)';
        
        -- Verifica a integridade dos dados inseridos
        SELECT 
            'Verificação de Integridade' AS Tipo,
            COUNT(*) AS TotalRegistros,
            MIN(Data) AS PrimeiraData,
            MAX(Data) AS UltimaData,
            COUNT(DISTINCT Ano) AS TotalAnos,
            COUNT(DISTINCT DataKey) AS TotalDataKeys
        FROM Shared.DimTempo
        WHERE Data BETWEEN @MinData AND @MaxData;
        
    END TRY
    BEGIN CATCH
        -- Tratamento de erro
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        PRINT 'ERRO durante a carga otimizada da DimTempo:';
        PRINT 'Mensagem: ' + @ErrorMessage;
        PRINT 'Registros inseridos antes do erro: ' + CAST(@RegistrosInseridos AS VARCHAR(10));
        
        -- Limpa tabela temporária em caso de erro
        IF OBJECT_ID('tempdb..#TempDimTempo') IS NOT NULL
            DROP TABLE #TempDimTempo;
        
        -- Re-lança o erro
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO

-- =============================================
-- Script para executar a stored procedure
-- =============================================

-- Executa a carga da DimTempo (CORRIGIDO: schema correto)
EXEC DM_ContratosProdutos.uspLoadDimTempo;

-- Consulta para verificar os dados carregados
SELECT TOP 10
    DataKey,
    Data,
    Ano,
    Mes,
    Trimestre,
    Semestre,
    NomeMes,
    DiaSemana,
    NomeDiaSemana
FROM Shared.DimTempo
ORDER BY Data;

-- Estatísticas por ano
SELECT 
    Ano,
    COUNT(*) AS TotalDias,
    MIN(Data) AS PrimeiraData,
    MAX(Data) AS UltimaData
FROM Shared.DimTempo
GROUP BY Ano
ORDER BY Ano;

