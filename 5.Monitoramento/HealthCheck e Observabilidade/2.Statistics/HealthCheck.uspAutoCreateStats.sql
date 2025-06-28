ALTER PROCEDURE HealthCheck.uspAutoCreateStats
(
    @MostrarStatistica              BIT = 1,
    @Efetivar                       BIT = 0,
    @NumberLinesToDetermineFullScan INT = 100000,
    @Debug                          BIT = 0  -- Novo parâmetro para logs detalhados
)
AS
    BEGIN TRY
        SET NOCOUNT ON;
        SET TRAN ISOLATION LEVEL READ UNCOMMITTED;

        /* ==================================================================
        --Data: 01/11/2018 
        --Autor: Wesley Neves
        --Observação: Cria as Statisticas Colunares
        --Última Otimização: [Data Atual] - Substituição de cursor por operações set-based
        -- ==================================================================
        */

        -- Variáveis de controle e log
        DECLARE @StartTime DATETIME2 = SYSDATETIME();
        DECLARE @TotalStats INT = 0;
        DECLARE @ProcessedStats INT = 0;
        DECLARE @Mensagem NVARCHAR(500);

        -- Log de início
        IF @Debug = 1
        BEGIN
            SET @Mensagem = N'[DEBUG] Iniciando análise de estatísticas em: ' + CONVERT(NVARCHAR(30), @StartTime, 121);
            RAISERROR(@Mensagem, 0, 1) WITH NOWAIT;
        END;

        -- Criação da tabela temporária otimizada
        IF OBJECT_ID('TEMPDB..#CreateStats') IS NOT NULL
            DROP TABLE #CreateStats;

        CREATE TABLE #CreateStats
        (
            RowId      INT IDENTITY(1,1) PRIMARY KEY,  -- Chave primária para controle de loop
            ObjectId   INT NOT NULL,
            SchemaName SYSNAME NOT NULL,               -- Tipo otimizado para nomes de schema
            TableName  SYSNAME NOT NULL,               -- Tipo otimizado para nomes de tabela
            Rows       BIGINT NOT NULL,
            ColumnId   INT NOT NULL,
            ColumnName SYSNAME NOT NULL,               -- Renomeado e otimizado
            DataType   SYSNAME NOT NULL,               -- Renomeado e otimizado
            UserTypeId INT NOT NULL,
            MaxLength  SMALLINT NOT NULL,
            Precision  TINYINT NOT NULL,
            IsNullable BIT NOT NULL,
            IsComputed BIT NOT NULL,
            Script     NVARCHAR(500) NOT NULL          -- Otimizado para tamanho real necessário
        );

        -- Índice para otimizar a busca durante o processamento
        CREATE NONCLUSTERED INDEX IX_CreateStats_ObjectId_ColumnId 
        ON #CreateStats (ObjectId, ColumnId);

        -- CTE otimizada para identificar colunas sem estatísticas
        WITH ColunasSemEstatisticas AS
        (
            SELECT 
                T.object_id,
                SchemaName = S.name,
                TableName = T.name,
                Rows = PS.row_count,  -- Usando sys.dm_db_partition_stats (mais moderno)
                C.column_id,
                ColumnName = C.name,
                DataType = TP.name,
                C.user_type_id,
                C.max_length,
                C.precision,
                C.is_nullable,
                C.is_computed
            FROM sys.tables T
                INNER JOIN sys.schemas S ON T.schema_id = S.schema_id
                INNER JOIN sys.columns C ON T.object_id = C.object_id
                INNER JOIN sys.types TP ON TP.user_type_id = C.user_type_id
                INNER JOIN sys.dm_db_partition_stats PS ON PS.object_id = T.object_id 
                    AND PS.index_id IN (0, 1)  -- Heap ou Clustered Index
                    AND PS.partition_number = 1
            WHERE
                -- Filtros de exclusão otimizados
                C.is_replicated = 0
                AND C.is_filestream = 0
                AND C.is_xml_document = 0
                AND C.is_computed = 0  -- Excluir colunas computadas
                AND TP.is_table_type = 0
                AND PS.row_count > 500  -- Aumentado o limite mínimo de linhas
                AND C.column_id > 1     -- Excluir primeira coluna (geralmente PK)
                
                -- Filtros de tipos de dados otimizados
                AND TP.name NOT IN ('varbinary', 'xml', 'text', 'ntext', 'image', 'sql_variant', 'hierarchyid', 'geometry', 'geography')
                AND NOT (TP.name IN ('varchar', 'nvarchar', 'char', 'nchar') AND C.max_length = -1)  -- Excluir MAX
                AND NOT (TP.name IN ('varchar', 'nvarchar') AND C.max_length > 100)  -- Limite mais flexível
                
                -- Filtros de schema e determinismo
                AND S.name NOT IN ('Log', 'sys', 'INFORMATION_SCHEMA')
                AND COLUMNPROPERTY(T.object_id, C.name, 'IsDeterministic') IS NULL
                
                -- Verificar se a coluna não possui estatísticas
                AND NOT EXISTS (
                    SELECT 1
                    FROM sys.stats ST
                        INNER JOIN sys.stats_columns SC ON ST.object_id = SC.object_id
                            AND ST.stats_id = SC.stats_id
                    WHERE ST.object_id = T.object_id
                        AND SC.column_id = C.column_id
                        AND SC.stats_column_id = 1  -- Apenas primeira coluna da estatística
                )
                
                -- Verificar se a tabela é utilizada (tem atividade de índice)
                AND EXISTS (
                    SELECT 1
                    FROM sys.dm_db_index_usage_stats IUS
                    WHERE IUS.object_id = T.object_id
                        AND (IUS.user_seeks + IUS.user_scans + IUS.user_lookups) > 10  -- Mínimo de atividade
                )
        )
        -- Inserção otimizada com script de criação melhorado
        INSERT INTO #CreateStats (
            ObjectId, SchemaName, TableName, Rows, ColumnId, ColumnName, 
            DataType, UserTypeId, MaxLength, Precision, IsNullable, IsComputed, Script
        )
        SELECT 
            CSS.object_id,
            CSS.SchemaName,
            CSS.TableName,
            CSS.Rows,
            CSS.column_id,
            CSS.ColumnName,
            CSS.DataType,
            CSS.user_type_id,
            CSS.max_length,
            CSS.precision,
            CSS.is_nullable,
            CSS.is_computed,
            -- Script otimizado com nomenclatura para identificação automática
            Script = CONCAT(
                'CREATE STATISTICS [AUTO_STATS_', 
                CSS.SchemaName, '_', CSS.TableName, '_', CSS.ColumnName, '_', FORMAT(GETDATE(), 'yyyyMMdd'), '] ',
                'ON [', CSS.SchemaName, '].[', CSS.TableName, '] ([', CSS.ColumnName, '])',
                CASE 
                    WHEN CSS.Rows <= @NumberLinesToDetermineFullScan THEN ' WITH FULLSCAN'
                    ELSE ''
                END
            )
        FROM ColunasSemEstatisticas CSS;

        -- Contagem total para logs
        SET @TotalStats = @@ROWCOUNT;

        -- Log de estatísticas encontradas
        IF @Debug = 1
        BEGIN
            SET @Mensagem = N'[DEBUG] Total de estatísticas a serem criadas: ' + CAST(@TotalStats AS NVARCHAR(10));
            RAISERROR(@Mensagem, 0, 1) WITH NOWAIT;
        END;

        -- Processamento otimizado sem cursor (set-based)
        IF EXISTS (SELECT 1 FROM #CreateStats) AND @Efetivar = 1
        BEGIN
            -- Variáveis para controle do loop otimizado
            DECLARE @CurrentRowId INT = 1;
            DECLARE @MaxRowId INT;
            DECLARE @BatchSize INT = 10;  -- Processar em lotes para melhor controle
            DECLARE @Script NVARCHAR(500);
            DECLARE @SchemaName SYSNAME;
            DECLARE @TableName SYSNAME;
            DECLARE @ColumnName SYSNAME;
            DECLARE @ExecutionStartTime DATETIME2;
            DECLARE @ExecutionTime INT;

            -- Obter o máximo RowId para controle do loop
            SELECT @MaxRowId = MAX(RowId) FROM #CreateStats;

            -- Log de início do processamento
            IF @Debug = 1
            BEGIN
                SET @Mensagem = N'[DEBUG] Iniciando criação de ' + CAST(@TotalStats AS NVARCHAR(10)) + N' estatísticas...';
                RAISERROR(@Mensagem, 0, 1) WITH NOWAIT;
            END;

            -- Loop otimizado para processar estatísticas
            WHILE @CurrentRowId <= @MaxRowId
            BEGIN
                -- Buscar dados da estatística atual
                SELECT 
                    @Script = Script,
                    @SchemaName = SchemaName,
                    @TableName = TableName,
                    @ColumnName = ColumnName
                FROM #CreateStats 
                WHERE RowId = @CurrentRowId;

                -- Verificar se encontrou registro (pode haver gaps nos IDs)
                IF @@ROWCOUNT > 0
                BEGIN
                    SET @ExecutionStartTime = SYSDATETIME();

                    -- Executar o script de criação da estatística
                    BEGIN TRY
                        EXEC sys.sp_executesql @Script;
                        SET @ProcessedStats = @ProcessedStats + 1;
                        
                        SET @ExecutionTime = DATEDIFF(MILLISECOND, @ExecutionStartTime, SYSDATETIME());

                        -- Log detalhado se solicitado
                        IF @MostrarStatistica = 1 OR @Debug = 1
                        BEGIN
                            SET @Mensagem = CONCAT(
                                N'[', @ProcessedStats, N'/', @TotalStats, N'] ',
                                N'Estatística criada: [', @SchemaName, N'].[', @TableName, N'].[', @ColumnName, N'] ',
                                N'(', @ExecutionTime, N'ms)'
                            );
                            RAISERROR(@Mensagem, 0, 1) WITH NOWAIT;
                        END;
                    END TRY
                    BEGIN CATCH
                        -- Log de erro sem interromper o processamento
                        SET @Mensagem = CONCAT(
                            N'[ERRO] Falha ao criar estatística: [', @SchemaName, N'].[', @TableName, N'].[', @ColumnName, N'] - ',
                            ERROR_MESSAGE()
                        );
                        RAISERROR(@Mensagem, 0, 1) WITH NOWAIT;
                    END CATCH;
                END;

                SET @CurrentRowId = @CurrentRowId + 1;

                -- Log de progresso a cada lote
                IF @Debug = 1 AND @ProcessedStats % @BatchSize = 0
                BEGIN
                    SET @Mensagem = N'[DEBUG] Progresso: ' + CAST(@ProcessedStats AS NVARCHAR(10)) + N'/' + CAST(@TotalStats AS NVARCHAR(10)) + N' estatísticas processadas';
                    RAISERROR(@Mensagem, 0, 1) WITH NOWAIT;
                END;
            END;

            -- Log final de conclusão
            IF @Debug = 1
            BEGIN
                DECLARE @TotalTime INT = DATEDIFF(MILLISECOND, @StartTime, SYSDATETIME());
                SET @Mensagem = N'[DEBUG] Processamento concluído: ' + CAST(@ProcessedStats AS NVARCHAR(10)) + N' estatísticas criadas em ' + CAST(@TotalTime AS NVARCHAR(10)) + N'ms';
                RAISERROR(@Mensagem, 0, 1) WITH NOWAIT;
            END;
        END;

        -- Seção de visualização otimizada
        IF @MostrarStatistica = 1
        BEGIN
            -- Exibir resumo geral das estatísticas
            SELECT 
                'RESUMO GERAL' AS Categoria,
                CAST(COUNT(*) AS NVARCHAR(50)) AS Valor,
                'Total de estatísticas identificadas' AS Descricao
            FROM #CreateStats
            
            UNION ALL
            
            SELECT 
                'FULLSCAN',
                CAST(COUNT(CASE WHEN Rows <= @NumberLinesToDetermineFullScan THEN 1 END) AS NVARCHAR(50)),
                'Estatísticas com FULLSCAN'
            FROM #CreateStats
            
            UNION ALL
            
            SELECT 
                'SEM_FULLSCAN',
                CAST(COUNT(CASE WHEN Rows > @NumberLinesToDetermineFullScan THEN 1 END) AS NVARCHAR(50)),
                'Estatísticas sem FULLSCAN'
            FROM #CreateStats
            
            UNION ALL
            
            SELECT 
                'MIN_LINHAS',
                CAST(ISNULL(MIN(Rows), 0) AS NVARCHAR(50)),
                'Mínimo de linhas nas tabelas'
            FROM #CreateStats
            
            UNION ALL
            
            SELECT 
                'MAX_LINHAS',
                CAST(ISNULL(MAX(Rows), 0) AS NVARCHAR(50)),
                'Máximo de linhas nas tabelas'
            FROM #CreateStats
            
            UNION ALL
            
            SELECT 
                'MEDIA_LINHAS',
                CAST(ISNULL(AVG(Rows), 0) AS NVARCHAR(50)),
                'Média de linhas nas tabelas'
            FROM #CreateStats
            ORDER BY Categoria;
            
            -- Exibir resumo por schema
            SELECT 
                'Resumo por Schema' AS TipoRelatorio,
                SchemaName,
                COUNT(*) AS QtdEstatisticas,
                COUNT(CASE WHEN Rows <= @NumberLinesToDetermineFullScan THEN 1 END) AS ComFullScan,
                COUNT(CASE WHEN Rows > @NumberLinesToDetermineFullScan THEN 1 END) AS SemFullScan,
                MIN(Rows) AS MinLinhas,
                MAX(Rows) AS MaxLinhas,
                AVG(Rows) AS MediaLinhas
            FROM #CreateStats
            GROUP BY SchemaName
            ORDER BY SchemaName;

            -- Exibir detalhes das estatísticas
            SELECT 
                RowId,
                SchemaName,
                TableName,
                ColumnName,
                DataType,
                Rows,
                CASE WHEN Rows <= @NumberLinesToDetermineFullScan THEN 'SIM' ELSE 'NÃO' END AS UsaFullScan,
                Script
            FROM #CreateStats
            ORDER BY SchemaName, TableName, ColumnName;
        END;

        -- Log final de conclusão
        IF @Debug = 1 OR @MostrarStatistica = 1
        BEGIN
            DECLARE @FinalTime INT = DATEDIFF(MILLISECOND, @StartTime, SYSDATETIME());
            SET @Mensagem = N'[INFO] Procedure concluída: ' + 
                           CAST(@TotalStats AS NVARCHAR(10)) + N' estatísticas identificadas, ' +
                           CAST(@ProcessedStats AS NVARCHAR(10)) + N' processadas em ' + 
                           CAST(@FinalTime AS NVARCHAR(10)) + N'ms';
            RAISERROR(@Mensagem, 0, 1) WITH NOWAIT;
        END;

    END TRY
    BEGIN CATCH
        -- Tratamento de erro otimizado
        DECLARE @ErrorNumber INT = ERROR_NUMBER();
        DECLARE @ErrorLine INT = ERROR_LINE();
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        DECLARE @ErrorProcedure NVARCHAR(128) = ISNULL(ERROR_PROCEDURE(), 'uspAutoCreateStats');

        -- Log detalhado do erro
        SET @Mensagem = CONCAT(
            N'[ERRO CRÍTICO] Procedure: ', @ErrorProcedure,
            N' | Linha: ', @ErrorLine,
            N' | Número: ', @ErrorNumber,
            N' | Mensagem: ', @ErrorMessage
        );
        
        RAISERROR(@Mensagem, 0, 1) WITH NOWAIT;

        -- Re-lançar o erro original
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);

    END CATCH;
GO
