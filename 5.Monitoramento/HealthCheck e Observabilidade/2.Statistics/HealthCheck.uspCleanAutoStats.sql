/*
==============================================================================
Procedure: HealthCheck.uspCleanAutoStats
Descrição: Remove estatísticas criadas automaticamente pela uspAutoCreateStats
           para evitar conflitos durante deploys no Azure DevOps

Autor: Sistema HealthCheck
Data: 2024
Versão: 1.0

Parâmetros:
    @Debug BIT = 0          - Habilita logs detalhados
    @ExecuteCleanup BIT = 0 - Executa a remoção (0 = apenas visualiza)
    @SchemaFilter NVARCHAR(128) = NULL - Filtra por esquema específico
    @TableFilter NVARCHAR(128) = NULL  - Filtra por tabela específica

Exemplos de uso:
    -- Visualizar estatísticas que seriam removidas
    EXEC HealthCheck.uspCleanAutoStats @Debug = 1, @ExecuteCleanup = 0
    
    -- Remover todas as estatísticas automáticas
    EXEC HealthCheck.uspCleanAutoStats @ExecuteCleanup = 1
    
    -- Remover apenas de um esquema específico
    EXEC HealthCheck.uspCleanAutoStats @ExecuteCleanup = 1, @SchemaFilter = 'dbo'
==============================================================================
*/

CREATE OR ALTER PROCEDURE HealthCheck.uspCleanAutoStats
    @Debug BIT = 0,
    @ExecuteCleanup BIT = 0,
    @SchemaFilter NVARCHAR(128) = NULL,
    @TableFilter NVARCHAR(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTime DATETIME2 = GETDATE();
    DECLARE @TotalStats INT = 0;
    DECLARE @RemovedStats INT = 0;
    DECLARE @ErrorCount INT = 0;
    DECLARE @CurrentScript NVARCHAR(MAX);
    DECLARE @CurrentRow INT = 1;
    DECLARE @MaxRow INT;
    
    -- Log de início
    IF @Debug = 1
    BEGIN
        PRINT CONCAT('[', FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'), '] Iniciando limpeza de estatísticas automáticas...');
        PRINT CONCAT('Parâmetros: ExecuteCleanup=', @ExecuteCleanup, ', SchemaFilter=', ISNULL(@SchemaFilter, 'NULL'), ', TableFilter=', ISNULL(@TableFilter, 'NULL'));
    END
    
    -- Tabela temporária para armazenar estatísticas a serem removidas
    CREATE TABLE #StatsToRemove (
        RowId INT IDENTITY(1,1) PRIMARY KEY,
        SchemaName NVARCHAR(128) NOT NULL,
        TableName NVARCHAR(128) NOT NULL,
        StatsName NVARCHAR(128) NOT NULL,
        DropScript NVARCHAR(500) NOT NULL,
        LastUpdated DATETIME NULL
    );
    
    -- Identificar estatísticas automáticas criadas pela uspAutoCreateStats
    INSERT INTO #StatsToRemove (SchemaName, TableName, StatsName, DropScript, LastUpdated)
    SELECT 
        s.name AS SchemaName,
        t.name AS TableName,
        st.name AS StatsName,
        CONCAT('DROP STATISTICS [', s.name, '].[', t.name, '].[', st.name, ']') AS DropScript,
        STATS_DATE(st.object_id, st.stats_id) AS LastUpdated
    FROM sys.stats st
    INNER JOIN sys.tables t ON st.object_id = t.object_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE st.name LIKE 'AUTO_STATS_%'  -- Estatísticas criadas pela uspAutoCreateStats
        AND st.user_created = 1  -- Apenas estatísticas criadas pelo usuário
        AND (@SchemaFilter IS NULL OR s.name = @SchemaFilter)
        AND (@TableFilter IS NULL OR t.name = @TableFilter)
    ORDER BY s.name, t.name, st.name;
    
    SELECT @TotalStats = COUNT(*), @MaxRow = MAX(RowId)
    FROM #StatsToRemove;
    
    -- Log do total encontrado
    IF @Debug = 1
        PRINT CONCAT('[', FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'), '] Encontradas ', @TotalStats, ' estatísticas automáticas para processamento.');
    
    -- Se não está executando, apenas mostra o que seria removido
    IF @ExecuteCleanup = 0
    BEGIN
        PRINT '=== PREVIEW - Estatísticas que seriam removidas ===';
        
        SELECT 
            SchemaName,
            TableName,
            StatsName,
            DropScript,
            LastUpdated,
            CASE 
                WHEN LastUpdated IS NOT NULL 
                THEN DATEDIFF(DAY, LastUpdated, GETDATE()) 
                ELSE NULL 
            END AS DaysSinceLastUpdate
        FROM #StatsToRemove
        ORDER BY SchemaName, TableName, StatsName;
        
        -- Resumo por esquema
        SELECT 
            'RESUMO POR ESQUEMA' AS Tipo,
            SchemaName,
            COUNT(*) AS TotalEstatisticas,
            MIN(LastUpdated) AS UltimaAtualizacaoMaisAntiga,
            MAX(LastUpdated) AS UltimaAtualizacaoMaisRecente
        FROM #StatsToRemove
        GROUP BY SchemaName
        ORDER BY SchemaName;
        
        PRINT CONCAT('Total de estatísticas que seriam removidas: ', @TotalStats);
        PRINT 'Para executar a remoção, use @ExecuteCleanup = 1';
    END
    ELSE
    BEGIN
        -- Executar remoção das estatísticas
        PRINT '=== EXECUTANDO REMOÇÃO DE ESTATÍSTICAS ===';
        
        WHILE @CurrentRow <= @MaxRow
        BEGIN
            SELECT @CurrentScript = DropScript
            FROM #StatsToRemove
            WHERE RowId = @CurrentRow;
            
            BEGIN TRY
                IF @Debug = 1
                    PRINT CONCAT('[', FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'), '] Executando (', @CurrentRow, '/', @MaxRow, '): ', @CurrentScript);
                
                EXEC sp_executesql @CurrentScript;
                SET @RemovedStats = @RemovedStats + 1;
                
                -- Log de progresso a cada 10 estatísticas
                IF @CurrentRow % 10 = 0 AND @Debug = 1
                    PRINT CONCAT('[', FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'), '] Progresso: ', @CurrentRow, '/', @MaxRow, ' (', @RemovedStats, ' removidas, ', @ErrorCount, ' erros)');
                    
            END TRY
            BEGIN CATCH
                SET @ErrorCount = @ErrorCount + 1;
                
                PRINT CONCAT('ERRO ao executar: ', @CurrentScript);
                PRINT CONCAT('Mensagem: ', ERROR_MESSAGE());
                
                IF @Debug = 1
                BEGIN
                    PRINT CONCAT('Erro Número: ', ERROR_NUMBER());
                    PRINT CONCAT('Severidade: ', ERROR_SEVERITY());
                    PRINT CONCAT('Estado: ', ERROR_STATE());
                    PRINT CONCAT('Linha: ', ERROR_LINE());
                END
            END CATCH
            
            SET @CurrentRow = @CurrentRow + 1;
        END
        
        -- Relatório final
        DECLARE @Duration INT = DATEDIFF(SECOND, @StartTime, GETDATE());
        
        PRINT '=== RELATÓRIO FINAL DE LIMPEZA ===';
        PRINT CONCAT('Estatísticas encontradas: ', @TotalStats);
        PRINT CONCAT('Estatísticas removidas: ', @RemovedStats);
        PRINT CONCAT('Erros encontrados: ', @ErrorCount);
        PRINT CONCAT('Tempo de execução: ', @Duration, ' segundos');
        
        IF @ErrorCount > 0
            PRINT 'ATENÇÃO: Alguns erros ocorreram durante a remoção. Verifique os logs acima.';
        ELSE
            PRINT 'Limpeza concluída com sucesso!';
    END
    
    -- Limpeza
    DROP TABLE #StatsToRemove;
    
END
GO

-- Comentários de uso e integração com Azure DevOps
/*
=== INTEGRAÇÃO COM AZURE DEVOPS ===

1. PRÉ-DEPLOY (antes de alterações de schema):
   EXEC HealthCheck.uspCleanAutoStats @ExecuteCleanup = 1, @Debug = 1

2. PÓS-DEPLOY (recriar estatísticas após deploy):
   EXEC HealthCheck.uspAutoCreateStats @Debug = 1

3. MONITORAMENTO (verificar estatísticas existentes):
   EXEC HealthCheck.uspCleanAutoStats @ExecuteCleanup = 0, @Debug = 1

=== EXEMPLO DE PIPELINE YAML ===

steps:
- task: SqlAzureDacpacDeployment@1
  displayName: 'Limpar Estatísticas Automáticas'
  inputs:
    azureSubscription: '$(azureSubscription)'
    ServerName: '$(serverName)'
    DatabaseName: '$(databaseName)'
    SqlUsername: '$(sqlUsername)'
    SqlPassword: '$(sqlPassword)'
    deployType: 'InlineSqlTask'
    SqlInline: 'EXEC HealthCheck.uspCleanAutoStats @ExecuteCleanup = 1, @Debug = 1'

- task: SqlAzureDacpacDeployment@1
  displayName: 'Deploy Database Changes'
  inputs:
    azureSubscription: '$(azureSubscription)'
    ServerName: '$(serverName)'
    DatabaseName: '$(databaseName)'
    SqlUsername: '$(sqlUsername)'
    SqlPassword: '$(sqlPassword)'
    deployType: 'DacpacTask'
    DeploymentAction: 'Publish'
    DacpacFile: '$(Pipeline.Workspace)/dacpac/$(dacpacName)'

- task: SqlAzureDacpacDeployment@1
  displayName: 'Recriar Estatísticas Automáticas'
  inputs:
    azureSubscription: '$(azureSubscription)'
    ServerName: '$(serverName)'
    DatabaseName: '$(databaseName)'
    SqlUsername: '$(sqlUsername)'
    SqlPassword: '$(sqlPassword)'
    deployType: 'InlineSqlTask'
    SqlInline: 'EXEC HealthCheck.uspAutoCreateStats @Debug = 1'
*/