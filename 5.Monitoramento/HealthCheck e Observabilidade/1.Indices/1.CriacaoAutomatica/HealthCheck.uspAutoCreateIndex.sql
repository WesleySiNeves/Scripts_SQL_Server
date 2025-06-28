--EXEC HealthCheck.uspAutoCreateIndex @Efetivar = 0,             -- bit
--                                    @VisualizarMissing = 1,    -- bit
--                                    @VisualizarCreate = 1,     -- bit
--                                    @VisualizarAlteracoes = 1, -- bit
--                                    @defaultTunningPerform = 100    -- smallint

ALTER PROCEDURE HealthCheck.uspAutoCreateIndex
(
    @Efetivar              BIT      = 0,
    @VisualizarMissing     BIT      = 0,
    @VisualizarCreate      BIT      = 0,
    @VisualizarAlteracoes  BIT      = 0,
    @defaultTunningPerform SMALLINT = 200,
    -- Novos parâmetros de controle e otimização
    @MaxIndicesProcessar   INT      = 50,     -- Limite máximo de índices a processar por execução
    @TamanhoLote          INT      = 10,     -- Tamanho do lote para processamento
    @MaxTabelasProcessar  INT      = 20,     -- Limite máximo de tabelas a processar
    @LimiteMemoriaMB      INT      = 500,    -- Limite de memória estimado em MB
    @TimeoutSegundos      INT      = 300,    -- Timeout em segundos
    @ModoDebug            BIT      = 0,      -- Modo debug para logs detalhados
    @SomenteAnalise       BIT      = 0       -- Apenas análise, sem execução
)
AS
BEGIN
    BEGIN TRY
        -- Configurações iniciais otimizadas
        SET TRAN ISOLATION LEVEL READ UNCOMMITTED;
        SET NOCOUNT ON;

        --DECLARE @Efetivar BIT = 0,
        --        @VisualizarMissing BIT = 0,
        --        @VisualizarCreate BIT = 0,
        --        @VisualizarAlteracoes BIT = 0,
        --        @defaultTunningPerform SMALLINT = 200,
        --                                       -- Novos parâmetros de controle e otimização
        --        @MaxIndicesProcessar INT = 50, -- Limite máximo de índices a processar por execução
        --        @TamanhoLote INT = 10,         -- Tamanho do lote para processamento
        --        @MaxTabelasProcessar INT = 20, -- Limite máximo de tabelas a processar
        --        @LimiteMemoriaMB INT = 500,    -- Limite de memória estimado em MB
        --        @TimeoutSegundos INT = 300,    -- Timeout em segundos
        --        @ModoDebug BIT = 0,            -- Modo debug para logs detalhados
        --        @SomenteAnalise BIT = 0;       -- Apenas análise, sem execução


        -- Variáveis de controle e monitoramento
        DECLARE @InicioExecucao DATETIME2 = GETDATE();
        DECLARE @SqlServerVersion VARCHAR(100) = @@VERSION;
        DECLARE @TipoVersao VARCHAR(100) = CASE
                                               WHEN CHARINDEX('Azure', @SqlServerVersion) > 0 THEN
                                                   'Azure'
                                               WHEN CHARINDEX('Enterprise', @SqlServerVersion) > 0 THEN
                                                   'Enterprise'
                                               ELSE
                                                   'Standard'
                                           END;

        -- Variáveis de controle otimizadas
        DECLARE @tableObjectsIds AS TableIntegerIds;
        DECLARE @QuantidadeMaximaIndiceTabela TINYINT = 5; -- (1 PK + 4 NonCluster)
        DECLARE @ContadorProcessados INT = 0;
        DECLARE @MemoriaUtilizada BIGINT = 0;
        DECLARE @LogMensagem NVARCHAR(500);

        -- Validações de entrada
        IF @MaxIndicesProcessar <= 0
            SET @MaxIndicesProcessar = 50;
        IF @TamanhoLote <= 0
            SET @TamanhoLote = 10;
        IF @MaxTabelasProcessar <= 0
            SET @MaxTabelasProcessar = 20;

        -- Log inicial se modo debug ativo
        IF @ModoDebug = 1
        BEGIN
            SET @LogMensagem
                = CONCAT('Iniciando execução - Versão: ', @TipoVersao, ' - Máx Índices: ', @MaxIndicesProcessar);
            RAISERROR(@LogMensagem, 0, 1) WITH NOWAIT;
        END;

        IF (OBJECT_ID('TEMPDB..#MissingIndex') IS NOT NULL)
            DROP TABLE #MissingIndex;

        IF (OBJECT_ID('TEMPDB..#IndexOnDataBase') IS NOT NULL)
            DROP TABLE #IndexOnDataBase;

        IF (OBJECT_ID('TEMPDB..#NovosIndices') IS NOT NULL)
            DROP TABLE #NovosIndices;

        IF (OBJECT_ID('TEMPDB..#InformacaoesOnTable') IS NOT NULL)
            DROP TABLE #InformacaoesOnTable;

        IF (OBJECT_ID('TEMPDB..#Parcial') IS NOT NULL)
            DROP TABLE #Parcial;

        IF (OBJECT_ID('TEMPDB..#Alteracoes') IS NOT NULL)
            DROP TABLE #Alteracoes;

        IF (OBJECT_ID('TEMPDB..#SchemasExcessao') IS NOT NULL)
            DROP TABLE #SchemasExcessao;

        -- Criação otimizada de tabelas temporárias com campos reduzidos
        CREATE TABLE #SchemasExcessao
        (
            SchemaName VARCHAR(128) NOT NULL
        );
        CREATE INDEX IX_SchemasExcessao ON #SchemasExcessao (SchemaName);

        INSERT INTO #SchemasExcessao
        (
            SchemaName
        )
        VALUES
        ('%HangFire%');

        CREATE TABLE #Alteracoes
        (
            RowId INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
            [ObjectId] INT NOT NULL,
            [SchemaName] VARCHAR(128) NOT NULL,
            [TableName] VARCHAR(128) NOT NULL,
            [Chave] VARCHAR(900),          -- Reduzido de 200 para 900 (limite do SQL)
            [PrimeiraChave] VARCHAR(128),  -- Reduzido de 200 para 128
            [ColunaIncluida] VARCHAR(900), -- Reduzido de 1000 para 900
            [CreateIndex] VARCHAR(4000),   -- Reduzido de 8000 para 4000
            [MagicBenefitNumber] REAL,
            [Melhor] DECIMAL(18, 2),
            ScriptDrop NVARCHAR(400),
            ScriptCreate NVARCHAR(400)
        );
        CREATE INDEX IX_Alteracoes_ObjectId
        ON #Alteracoes (
                           ObjectId,
                           PrimeiraChave
                       );

        CREATE TABLE #InformacaoesOnTable
        (
            ObjectId INT NOT NULL,
            [QuantidadeIndiceTabela] TINYINT NOT NULL
        );
        CREATE INDEX IX_InformacaoesOnTable ON #InformacaoesOnTable (ObjectId);

        CREATE TABLE #Parcial
        (
            RowId INT NOT NULL IDENTITY(1, 1) PRIMARY KEY,
            ObjectId INT NOT NULL,
            TotalObjetcId SMALLINT,
            SchemaName VARCHAR(128) NOT NULL,
            TableName VARCHAR(128) NOT NULL,
            IndexName VARCHAR(128),          -- Reduzido de 200 para 128
            [Chave] VARCHAR(900),            -- Reduzido de 200 para 900
            [PrimeiraChave] VARCHAR(128),    -- Reduzido de 200 para 128
            [ExisteIndiceNaChave] BIT,       -- Mudado de INT para BIT
            [ChavePertenceAOutroIndice] BIT, -- Mudado de INT para BIT
            [QuantidadeIndiceTabela] TINYINT,
            [ColunaIncluida] VARCHAR(900),   -- Reduzido de 1000 para 900
            AvgEstimatedImpact REAL,
            MagicBenefitNumber REAL,
            PotentialReadOp INT,
            [reads] INT,
            PercCusto DECIMAL(10, 2),
            [CreateIndex] VARCHAR(4000)      -- Reduzido de 8000 para 4000
        );
        CREATE INDEX IX_Parcial_ObjectId
        ON #Parcial (
                        ObjectId,
                        PrimeiraChave,
                        MagicBenefitNumber DESC
                    );

        IF (OBJECT_ID('TEMPDB..#ResultAllIndex') IS NOT NULL)
            DROP TABLE #ResultAllIndex;

        CREATE TABLE #ResultAllIndex
        (
            [ObjectId] INT,
            [ObjectName] VARCHAR(300),
            [RowsInTable] INT,
            [IndexName] VARCHAR(128),
            [Usado] BIT,
            [UserSeeks] INT,
            [UserScans] INT,
            [UserLookups] INT,
            [UserUpdates] INT,
            [Reads] BIGINT,
            [Write] INT,
            [CountPageSplitPage] INT,
            [PercAproveitamento] DECIMAL(18, 2),
            [PercCustoMedio] DECIMAL(18, 2),
            [IsBadIndex] INT,
            [IndexId] SMALLINT,
            [IndexsizeKB] BIGINT,
            [IndexsizeMB] DECIMAL(18, 2),
            [IndexSizePorTipoMB] DECIMAL(18, 2),
            [Chave] VARCHAR(899),
            PrimeiraChave AS
                (IIF(CHARINDEX(',', [Chave], 0) > 0, SUBSTRING([Chave], 0, CHARINDEX(',', [Chave], 0)), [Chave])),
            [ColunasIncluidas] VARCHAR(899),
            [IsUnique] BIT,
            [IgnoreDupKey] BIT,
            [IsprimaryKey] BIT,
            [IsUniqueConstraint] BIT,
            [FillFact] TINYINT,
            [AllowRowLocks] BIT,
            [AllowPageLocks] BIT,
            [HasFilter] BIT,
            [TypeIndex] TINYINT
        );

        IF EXISTS
        (
            SELECT 1
            FROM sys.syscursors AS S
            WHERE S.cursor_name = 'cursor_CreateOrAlterIndex'
        )
        BEGIN
            DEALLOCATE cursor_CreateOrAlterIndex;
        END;

        CREATE TABLE #IndexOnDataBase
        (
            [SnapShotDate] DATETIME2(3),
            ObjectId INT,
            [RowsInTable] INT,
            [ObjectName] VARCHAR(260),
            [index_id] SMALLINT,
            [IndexName] VARCHAR(128),
            [Reads] BIGINT,
            [Write] INT,
            [%Aproveitamento] DECIMAL(18, 2),
            [%Custo Medio] DECIMAL(18, 2),
            [Perc_scan] DECIMAL(10, 2),
            AvgPercScan DECIMAL(10, 2),
            [Media IsBad] INT,
            [Media Reads] DECIMAL(10, 2),
            [Media Writes] DECIMAL(10, 2),
            [Media Aproveitamento] DECIMAL(10, 2),
            [Media Custo] DECIMAL(10, 2),
            [IsBadIndex] BIT,
            [MaxAnaliseForTable] SMALLINT,
            [MaxAnaliseForIndex] INT,
            [QtdAnalize] INT,
            [Analise] SMALLINT,
            [is_unique_constraint] BIT,
            [is_primary_key] BIT,
            [is_unique] BIT
        );


        CREATE TABLE #MissingIndex
        (
            [ObjectId] INT,
            [TotalObjectId] INT,
            [SchemaName] VARCHAR(140),
            [TableName] VARCHAR(140),
            [IndexName] VARCHAR(200),
            [KeyColumns] VARCHAR(200),
            [FirstKeyColumn] VARCHAR(200),
            [ExistsIndexOnKey] INT,
            [KeyBelongsToOtherIndex] INT,
            [IncludedColumns] VARCHAR(1000),
            [AvgEstimatedImpact] REAL,
            [MagicBenefitNumber] REAL,
            [PotentialReadOperations] INT,
            [TotalReads] INT,
            [WriteReadRatioPercent] DECIMAL(10, 2),
            [Priority] VARCHAR(10),
            [CreateIndexScript] VARCHAR(8000)
        );
        CREATE INDEX IX_MissingIndex_ObjectId
        ON #MissingIndex (
                             ObjectId,
                             MagicBenefitNumber DESC
                         );

        CREATE TABLE #NovosIndices
        (
            RowId INT NOT NULL IDENTITY(1, 1) PRIMARY KEY,
            ObjectId INT NOT NULL,
            SchemaName VARCHAR(128) NOT NULL,
            TableName VARCHAR(128) NOT NULL,
            IndexName VARCHAR(128),          -- Reduzido de 200 para 128
            [Chave] VARCHAR(900),            -- Reduzido de 200 para 900
            [PrimeiraChave] VARCHAR(128),    -- Reduzido de 200 para 128
            [ExisteIndiceNaChave] BIT,       -- Mudado de INT para BIT
            [ChavePertenceAOutroIndice] BIT, -- Mudado de INT para BIT
            [QuantidadeIndiceTabela] TINYINT,
            [ColunaIncluida] VARCHAR(900),   -- Reduzido de 1000 para 900
            AvgEstimatedImpact REAL,
            MagicBenefitNumber REAL,
            PotentialReadOp INT,
            [reads] INT,
            PercCusto DECIMAL(10, 2),
            [CreateIndex] VARCHAR(4000),     -- Reduzido de 8000 para 4000
            AvgPercScan DECIMAL(10, 2)
        );
        CREATE INDEX IX_NovosIndices_ObjectId
        ON #NovosIndices (
                             ObjectId,
                             MagicBenefitNumber DESC
                         );

        -- Processamento otimizado com controle de lotes
        INSERT INTO #MissingIndex
        EXEC HealthCheck.uspMissingIndex @defaultTunningPerform = @defaultTunningPerform;

        -- Log de missing indexes encontrados
        IF @ModoDebug = 1
        BEGIN
            SELECT @ContadorProcessados = COUNT(*)
            FROM #MissingIndex;
            SET @LogMensagem = CONCAT('Missing indexes encontrados: ', @ContadorProcessados);
            RAISERROR(@LogMensagem, 0, 1) WITH NOWAIT;
        END;

        -- Aplicar limite máximo de índices a processar
        IF EXISTS (SELECT 1 FROM #MissingIndex)
        BEGIN
            WITH TopMissingIndexes
            AS (SELECT TOP (@MaxIndicesProcessar)
                       *,
                       ROW_NUMBER() OVER (ORDER BY MagicBenefitNumber DESC, AvgEstimatedImpact DESC) AS rn
                FROM #MissingIndex)
            DELETE MI
            FROM #MissingIndex MI
            WHERE NOT EXISTS
            (
                SELECT 1
                FROM TopMissingIndexes TMI
                WHERE TMI.ObjectId = MI.ObjectId
                      AND TMI.IndexName = MI.IndexName
            );
        END;

        -- Filtrar esquemas de exceção (otimizado)
        DELETE MI
        FROM #MissingIndex MI
        WHERE EXISTS
        (
            SELECT 1 FROM #SchemasExcessao SSE WHERE MI.SchemaName LIKE SSE.SchemaName
        );


        --Remover indices com pouca eficiencia
        DELETE FROM #MissingIndex
        WHERE Priority = 'BAIXA';


        -- Verificar se há missing indexes para processar
        IF EXISTS (SELECT 1 FROM #MissingIndex)
        BEGIN
            -- Log de início do processamento
            IF @ModoDebug = 1
            BEGIN
                SET @LogMensagem = N'Iniciando processamento de missing indexes...';
                RAISERROR(@LogMensagem, 0, 1) WITH NOWAIT;
            END;

            -- Inserir informações de tabelas (otimizado)
            INSERT INTO #InformacaoesOnTable
            (
                ObjectId,
                QuantidadeIndiceTabela
            )
            SELECT DISTINCT
                   MI.ObjectId,
                   COUNT(ISNULL(IX.index_id, 0))
            FROM #MissingIndex MI
                INNER JOIN sys.indexes IX
                    ON IX.object_id = MI.ObjectId
            WHERE IX.is_disabled = 0
                  AND IX.is_hypothetical = 0
                  AND IX.type > 0
            GROUP BY MI.ObjectId;

            -- Inserir dados na tabela parcial (otimizado)
            INSERT INTO #Parcial
            (
                ObjectId,
                TotalObjetcId,
                SchemaName,
                TableName,
                IndexName,
                Chave,
                PrimeiraChave,
                ExisteIndiceNaChave,
                ChavePertenceAOutroIndice,
                QuantidadeIndiceTabela,
                ColunaIncluida,
                AvgEstimatedImpact,
                MagicBenefitNumber,
                PotentialReadOp,
                reads,
                PercCusto,
                CreateIndex
            )
            SELECT MI.ObjectId,
                   MI.TotalObjectId,
                   MI.SchemaName,
                   MI.TableName,
                   MI.IndexName,
                   MI.KeyColumns,
                   MI.FirstKeyColumn,
                   MI.ExistsIndexOnKey,
                   MI.KeyBelongsToOtherIndex,
                   Info.QuantidadeIndiceTabela,
                   MI.IncludedColumns,
                   MI.AvgEstimatedImpact,
                   MI.MagicBenefitNumber,
                   MI.PotentialReadOperations,
                   MI.TotalReads,
                   MI.WriteReadRatioPercent,
                   MI.CreateIndexScript
            FROM #MissingIndex MI
                INNER JOIN #InformacaoesOnTable Info
                    ON MI.ObjectId = Info.ObjectId


            -- Seleção otimizada de novos índices (objetos únicos e múltiplos)
            -- Processamento em lote único para melhor performance
            ;
            WITH MelhoresIndices
            AS (SELECT ObjectId,
                       SchemaName,
                       TableName,
                       IndexName,
                       Chave,
                       PrimeiraChave,
                       ExisteIndiceNaChave,
                       ChavePertenceAOutroIndice,
                       QuantidadeIndiceTabela,
                       ColunaIncluida,
                       AvgEstimatedImpact,
                       MagicBenefitNumber,
                       PotentialReadOp,
                       reads,
                       PercCusto,
                       CreateIndex,
                       ROW_NUMBER() OVER (PARTITION BY ObjectId,
                                                       PrimeiraChave
                                          ORDER BY MagicBenefitNumber DESC,
                                                   AvgEstimatedImpact DESC
                                         ) AS rn
                FROM #Parcial
                WHERE ExisteIndiceNaChave = 0
                      AND ChavePertenceAOutroIndice = 0)
            INSERT INTO #NovosIndices
            (
                ObjectId,
                SchemaName,
                TableName,
                IndexName,
                Chave,
                PrimeiraChave,
                ExisteIndiceNaChave,
                ChavePertenceAOutroIndice,
                QuantidadeIndiceTabela,
                ColunaIncluida,
                AvgEstimatedImpact,
                MagicBenefitNumber,
                PotentialReadOp,
                reads,
                PercCusto,
                CreateIndex
            )
            SELECT ObjectId,
                   SchemaName,
                   TableName,
                   IndexName,
                   Chave,
                   PrimeiraChave,
                   ExisteIndiceNaChave,
                   ChavePertenceAOutroIndice,
                   QuantidadeIndiceTabela,
                   ColunaIncluida,
                   AvgEstimatedImpact,
                   MagicBenefitNumber,
                   PotentialReadOp,
                   reads,
                   PercCusto,
                   CreateIndex
            FROM MelhoresIndices
            WHERE rn = 1;


            -- Log de progresso em modo debug
            IF @ModoDebug = 1
            BEGIN
                SELECT @LogMensagem = N'Novos índices selecionados: ' + CAST(@@ROWCOUNT AS VARCHAR(10));
                RAISERROR(@LogMensagem, 0, 1) WITH NOWAIT;
            END;


            IF @ModoDebug = 1
            BEGIN
                SELECT @LogMensagem = N'Duplicatas removidas. Índices restantes: ' + CAST(
                (
                    SELECT COUNT(*)FROM #NovosIndices
                )   AS VARCHAR(10));
                RAISERROR(@LogMensagem, 0, 1) WITH NOWAIT;
            END;


            -- Processamento otimizado de alterações de índices existentes
            IF EXISTS (SELECT 1 FROM #Parcial WHERE ExisteIndiceNaChave = 1)
            BEGIN
                -- Seleção direta dos melhores índices para alteração
                WITH MelhoresAlteracoes
                AS (SELECT ObjectId,
                           SchemaName,
                           TableName,
                           Chave,
                           PrimeiraChave,
                           ColunaIncluida,
                           CreateIndex,
                           CAST(MagicBenefitNumber AS DECIMAL(18, 2)) AS MagicBenefitNumber,
                           ROW_NUMBER() OVER (PARTITION BY ObjectId,
                                                           PrimeiraChave
                                              ORDER BY MagicBenefitNumber DESC,
                                                       AvgEstimatedImpact DESC
                                             ) AS rn
                    FROM #Parcial
                    WHERE ExisteIndiceNaChave = 1)
                INSERT INTO #Alteracoes
                (
                    ObjectId,
                    SchemaName,
                    TableName,
                    Chave,
                    PrimeiraChave,
                    ColunaIncluida,
                    CreateIndex,
                    MagicBenefitNumber,
                    Melhor,
                    ScriptDrop,
                    ScriptCreate
                )
                SELECT ObjectId,
                       SchemaName,
                       TableName,
                       Chave,
                       PrimeiraChave,
                       ColunaIncluida,
                       CreateIndex,
                       MagicBenefitNumber,
                       MagicBenefitNumber,
                       NULL,
                       NULL
                FROM MelhoresAlteracoes
                WHERE rn = 1;


                INSERT INTO #ResultAllIndex
                EXEC HealthCheck.uspAllIndex @typeIndex = 'NONCLUSTERED'; -- varchar(40)



                -- Remove alterações para índices únicos e constraints (otimizado)
                DELETE FROM #Alteracoes
                WHERE EXISTS
                (
                    SELECT 1
                    FROM sys.indexes I
                        INNER JOIN sys.index_columns IC
                            ON I.object_id = IC.object_id
                               AND I.index_id = IC.index_id
                        INNER JOIN sys.columns C
                            ON IC.object_id = C.object_id
                               AND IC.column_id = C.column_id
                    WHERE I.is_unique = 1
                          AND I.is_unique_constraint = 1
                          AND I.object_id = #Alteracoes.ObjectId
                          AND #Alteracoes.PrimeiraChave = C.name COLLATE DATABASE_DEFAULT
                );

                IF @ModoDebug = 1
                BEGIN
                    SELECT @LogMensagem = N'Alterações após filtros: ' + CAST(
                    (
                        SELECT COUNT(*)FROM #Alteracoes
                    )   AS VARCHAR(10));
                    RAISERROR(@LogMensagem, 0, 1) WITH NOWAIT;
                END;


                -- Processamento otimizado de alterações (sem cursor)
                IF EXISTS (SELECT 1 FROM #Alteracoes WHERE ColunaIncluida IS NOT NULL)
                BEGIN
                    -- Atualiza scripts de alteração usando operações set-based
                    ;WITH AlteracoesComScripts
                     AS (SELECT A.RowId,
                                A.ObjectId,
                                A.SchemaName,
                                A.TableName,
                                A.Chave,
                                A.PrimeiraChave,
                                A.ColunaIncluida,
                                -- Encontra o índice com menor aproveitamento para DROP
                                (
                                    SELECT TOP 1
                                           RAI.IndexName
                                    FROM #ResultAllIndex RAI
                                    WHERE RAI.ObjectId = A.ObjectId
                                          AND RAI.PrimeiraChave = A.PrimeiraChave
                                          AND RAI.TypeIndex > 1
                                    ORDER BY RAI.PercAproveitamento ASC
                                ) AS IndexNameDrop,
                                -- Monta colunas incluídas otimizadas
                                A.ColunaIncluida AS NovasColunas
                         FROM #Alteracoes A
                         WHERE A.ColunaIncluida IS NOT NULL)
                    UPDATE #Alteracoes
                    SET ScriptDrop = 'DROP INDEX [' + ISNULL(ACS.IndexNameDrop, '') + '] ON [' + ISNULL(ACS.SchemaName, '') + '].[' + ISNULL(ACS.TableName, '') + '];',
                        ScriptCreate = ACS.NovasColunas
                    FROM #Alteracoes A
                        INNER JOIN AlteracoesComScripts ACS
                            ON A.RowId = ACS.RowId
                    WHERE ACS.IndexNameDrop IS NOT NULL;

                    -- Finaliza o processamento de alterações
                    IF @ModoDebug = 1
                    BEGIN
                        SELECT @LogMensagem = N'Scripts de alteração gerados: ' + CAST(
                        (
                            SELECT COUNT(*)FROM #Alteracoes WHERE ScriptDrop IS NOT NULL
                        )   AS VARCHAR(10));
                        RAISERROR(@LogMensagem, 0, 1) WITH NOWAIT;
                    END;
                END;
            END; -- Fim do processamento de alterações



            DECLARE @with VARCHAR(100) = CASE
                                              WHEN @TipoVersao IN ( 'Azure', 'Enterprise' ) THEN
                                                  'WITH(ONLINE =ON ,DATA_COMPRESSION =PAGE)'
                                              WHEN @TipoVersao IN ( 'Standard' ) THEN
                                                  'WITH(DATA_COMPRESSION =PAGE)'
                                              ELSE
                                                  ''
                                          END;

            UPDATE #NovosIndices
            SET CreateIndex = CONCAT(ISNULL(CreateIndex, ''), SPACE(2), ISNULL(@with, ''));

            UPDATE #Alteracoes
            SET CreateIndex = CONCAT(ISNULL(CreateIndex, ''), SPACE(2), ISNULL(@with, ''));


            -- ═══════════════════════════════════════════════════════════════
            -- 🔄 MERGE DE ÍNDICES ALTERADOS COM ÍNDICES EXISTENTES
            -- ═══════════════════════════════════════════════════════════════

            -- Criar tabela temporária para o merge final
            IF (OBJECT_ID('TEMPDB..#MergedIndexes') IS NOT NULL)
                DROP TABLE #MergedIndexes;

            CREATE TABLE #MergedIndexes
            (
                [ObjectId] INT,
                [ObjectName] VARCHAR(300),
                [RowsInTable] INT,
                [IndexName] VARCHAR(128),
                [Usado] BIT,
                [UserSeeks] INT,
                [UserScans] INT,
                [UserLookups] INT,
                [UserUpdates] INT,
                [Reads] BIGINT,
                [Write] INT,
                [CountPageSplitPage] INT,
                [PercAproveitamento] DECIMAL(18, 2),
                [PercCustoMedio] DECIMAL(18, 2),
                [IsBadIndex] INT,
                [IndexId] SMALLINT,
                [IndexsizeKB] BIGINT,
                [IndexsizeMB] DECIMAL(18, 2),
                [IndexSizePorTipoMB] DECIMAL(18, 2),
                [Chave] VARCHAR(899),
                [PrimeiraChave] VARCHAR(128),
                [ColunasIncluidas] VARCHAR(899),
                [IsUnique] BIT,
                [IgnoreDupKey] BIT,
                [IsprimaryKey] BIT,
                [IsUniqueConstraint] BIT,
                [FillFact] TINYINT,
                [AllowRowLocks] BIT,
                [AllowPageLocks] BIT,
                [HasFilter] BIT,
                [TypeIndex] TINYINT,
                [StatusMerge] VARCHAR(20), -- 'EXISTENTE', 'ALTERADO', 'NOVO'
                [MagicBenefitNumber] REAL,
                [CreateIndexScript] VARCHAR(4000),
                [ScriptDrop] NVARCHAR(400),
                [ScriptCreate] NVARCHAR(400)
            );

            -- 1. Inserir todos os índices existentes que NÃO serão alterados
            INSERT INTO #MergedIndexes
            (
                ObjectId,
                ObjectName,
                RowsInTable,
                IndexName,
                Usado,
                UserSeeks,
                UserScans,
                UserLookups,
                UserUpdates,
                Reads,
                Write,
                CountPageSplitPage,
                PercAproveitamento,
                PercCustoMedio,
                IsBadIndex,
                IndexId,
                IndexsizeKB,
                IndexsizeMB,
                IndexSizePorTipoMB,
                Chave,
                PrimeiraChave,
                ColunasIncluidas,
                IsUnique,
                IgnoreDupKey,
                IsprimaryKey,
                IsUniqueConstraint,
                FillFact,
                AllowRowLocks,
                AllowPageLocks,
                HasFilter,
                TypeIndex,
                StatusMerge,
                MagicBenefitNumber,
                CreateIndexScript,
                ScriptDrop,
                ScriptCreate
            )
            SELECT RAI.ObjectId,
                   RAI.ObjectName,
                   RAI.RowsInTable,
                   RAI.IndexName,
                   RAI.Usado,
                   RAI.UserSeeks,
                   RAI.UserScans,
                   RAI.UserLookups,
                   RAI.UserUpdates,
                   RAI.Reads,
                   RAI.Write,
                   RAI.CountPageSplitPage,
                   RAI.PercAproveitamento,
                   RAI.PercCustoMedio,
                   RAI.IsBadIndex,
                   RAI.IndexId,
                   RAI.IndexsizeKB,
                   RAI.IndexsizeMB,
                   RAI.IndexSizePorTipoMB,
                   RAI.Chave,
                   RAI.PrimeiraChave,
                   RAI.ColunasIncluidas,
                   RAI.IsUnique,
                   RAI.IgnoreDupKey,
                   RAI.IsprimaryKey,
                   RAI.IsUniqueConstraint,
                   RAI.FillFact,
                   RAI.AllowRowLocks,
                   RAI.AllowPageLocks,
                   RAI.HasFilter,
                   RAI.TypeIndex,
                   'EXISTENTE' AS StatusMerge,
                   NULL AS MagicBenefitNumber,
                   NULL AS CreateIndexScript,
                   NULL AS ScriptDrop,
                   NULL AS ScriptCreate
            FROM #ResultAllIndex RAI
            WHERE NOT EXISTS
            (
                SELECT 1
                FROM #Alteracoes A
                WHERE A.ObjectId = RAI.ObjectId
                      AND A.PrimeiraChave = RAI.PrimeiraChave
            );

            -- 2. Inserir índices que serão alterados (versão melhorada)
            INSERT INTO #MergedIndexes
            (
                ObjectId,
                ObjectName,
                RowsInTable,
                IndexName,
                Usado,
                UserSeeks,
                UserScans,
                UserLookups,
                UserUpdates,
                Reads,
                Write,
                CountPageSplitPage,
                PercAproveitamento,
                PercCustoMedio,
                IsBadIndex,
                IndexId,
                IndexsizeKB,
                IndexsizeMB,
                IndexSizePorTipoMB,
                Chave,
                PrimeiraChave,
                ColunasIncluidas,
                IsUnique,
                IgnoreDupKey,
                IsprimaryKey,
                IsUniqueConstraint,
                FillFact,
                AllowRowLocks,
                AllowPageLocks,
                HasFilter,
                TypeIndex,
                StatusMerge,
                MagicBenefitNumber,
                CreateIndexScript,
                ScriptDrop,
                ScriptCreate
            )
            SELECT ISNULL(RAI.ObjectId, A.ObjectId) AS ObjectId,
                   ISNULL(RAI.ObjectName, QUOTENAME(A.SchemaName) + '.' + QUOTENAME(A.TableName)) AS ObjectName,
                   ISNULL(RAI.RowsInTable, 0) AS RowsInTable,
                   -- Nome do índice alterado (mantém o original ou gera novo)
                   COALESCE(
                               RAI.IndexName,
                               'IX_' + A.SchemaName + '_' + A.TableName + '_' + REPLACE(A.PrimeiraChave, ',', '_')
                           ) AS IndexName,
                   ISNULL(RAI.Usado, 0) AS Usado,
                   ISNULL(RAI.UserSeeks, 0) AS UserSeeks,
                   ISNULL(RAI.UserScans, 0) AS UserScans,
                   ISNULL(RAI.UserLookups, 0) AS UserLookups,
                   ISNULL(RAI.UserUpdates, 0) AS UserUpdates,
                   ISNULL(RAI.Reads, 0) AS Reads,
                   ISNULL(RAI.Write, 0) AS Write,
                   ISNULL(RAI.CountPageSplitPage, 0) AS CountPageSplitPage,
                   ISNULL(RAI.PercAproveitamento, 0) AS PercAproveitamento,
                   ISNULL(RAI.PercCustoMedio, 0) AS PercCustoMedio,
                   ISNULL(RAI.IsBadIndex, 0) AS IsBadIndex,
                   ISNULL(RAI.IndexId, 999) AS IndexId,
                   ISNULL(RAI.IndexsizeKB, 0) AS IndexsizeKB,
                   ISNULL(RAI.IndexsizeMB, 0) AS IndexsizeMB,
                   ISNULL(RAI.IndexSizePorTipoMB, 0) AS IndexSizePorTipoMB,
                   -- Usar chaves e colunas incluídas da alteração
                   A.Chave,
                   A.PrimeiraChave,
                   A.ColunaIncluida AS ColunasIncluidas,
                   ISNULL(RAI.IsUnique, 0) AS IsUnique,
                   ISNULL(RAI.IgnoreDupKey, 0) AS IgnoreDupKey,
                   ISNULL(RAI.IsprimaryKey, 0) AS IsprimaryKey,
                   ISNULL(RAI.IsUniqueConstraint, 0) AS IsUniqueConstraint,
                   ISNULL(RAI.FillFact, 0) AS FillFact,
                   ISNULL(RAI.AllowRowLocks, 1) AS AllowRowLocks,
                   ISNULL(RAI.AllowPageLocks, 1) AS AllowPageLocks,
                   ISNULL(RAI.HasFilter, 0) AS HasFilter,
                   ISNULL(RAI.TypeIndex, 2) AS TypeIndex,
                   'ALTERADO' AS StatusMerge,
                   A.MagicBenefitNumber,
                   A.CreateIndex AS CreateIndexScript,
                   A.ScriptDrop,
                   A.ScriptCreate
            FROM #Alteracoes A
                LEFT JOIN #ResultAllIndex RAI
                    ON A.ObjectId = RAI.ObjectId
                       AND A.PrimeiraChave = RAI.PrimeiraChave;

            -- 3. Inserir novos índices que não existem
            INSERT INTO #MergedIndexes
            (
                ObjectId,
                ObjectName,
                RowsInTable,
                IndexName,
                Usado,
                UserSeeks,
                UserScans,
                UserLookups,
                UserUpdates,
                Reads,
                Write,
                CountPageSplitPage,
                PercAproveitamento,
                PercCustoMedio,
                IsBadIndex,
                IndexId,
                IndexsizeKB,
                IndexsizeMB,
                IndexSizePorTipoMB,
                Chave,
                PrimeiraChave,
                ColunasIncluidas,
                IsUnique,
                IgnoreDupKey,
                IsprimaryKey,
                IsUniqueConstraint,
                FillFact,
                AllowRowLocks,
                AllowPageLocks,
                HasFilter,
                TypeIndex,
                StatusMerge,
                MagicBenefitNumber,
                CreateIndexScript,
                ScriptDrop,
                ScriptCreate
            )
            SELECT NI.ObjectId,
                   QUOTENAME(NI.SchemaName) + '.' + QUOTENAME(NI.TableName) AS ObjectName,
                   0 AS RowsInTable, -- Será atualizado posteriormente
                   NI.IndexName,
                   0 AS Usado,
                   0 AS UserSeeks,
                   0 AS UserScans,
                   0 AS UserLookups,
                   0 AS UserUpdates,
                   0 AS Reads,
                   0 AS Write,
                   0 AS CountPageSplitPage,
                   0 AS PercAproveitamento,
                   0 AS PercCustoMedio,
                   0 AS IsBadIndex,
                   999 AS IndexId,   -- ID temporário para novos
                   0 AS IndexsizeKB,
                   0 AS IndexsizeMB,
                   0 AS IndexSizePorTipoMB,
                   NI.Chave,
                   NI.PrimeiraChave,
                   NI.ColunaIncluida AS ColunasIncluidas,
                   0 AS IsUnique,
                   0 AS IgnoreDupKey,
                   0 AS IsprimaryKey,
                   0 AS IsUniqueConstraint,
                   0 AS FillFact,
                   1 AS AllowRowLocks,
                   1 AS AllowPageLocks,
                   0 AS HasFilter,
                   2 AS TypeIndex,
                   'NOVO' AS StatusMerge,
                   NI.MagicBenefitNumber,
                   NI.CreateIndex AS CreateIndexScript,
                   NULL AS ScriptDrop,
                   NULL AS ScriptCreate
            FROM #NovosIndices NI
            WHERE NOT EXISTS
            (
                SELECT 1
                FROM #MergedIndexes MI
                WHERE MI.ObjectId = NI.ObjectId
                      AND MI.PrimeiraChave = NI.PrimeiraChave
            );

            -- 4. Atualizar informações de tabelas para novos índices
            UPDATE MI
            SET RowsInTable = ISNULL(
                              (
                                  SELECT si.rowcnt
                                  FROM sys.sysindexes si
                                  WHERE si.id = MI.ObjectId
                                        AND si.indid IN ( 0, 1 )
                              ),
                              0
                                    )
            FROM #MergedIndexes MI
            WHERE MI.StatusMerge = 'NOVO';

            -- Log de resultados do merge
            IF @ModoDebug = 1
            BEGIN
                DECLARE @TotalExistentes INT =
                        (
                            SELECT COUNT(*)FROM #MergedIndexes WHERE StatusMerge = 'EXISTENTE'
                        );
                DECLARE @TotalAlterados INT =
                        (
                            SELECT COUNT(*)FROM #MergedIndexes WHERE StatusMerge = 'ALTERADO'
                        );
                DECLARE @TotalNovosIdx INT =
                        (
                            SELECT COUNT(*)FROM #MergedIndexes WHERE StatusMerge = 'NOVO'
                        );

                SET @LogMensagem
                    = CONCAT(
                                'Merge concluído - Existentes: ',
                                @TotalExistentes,
                                ', Alterados: ',
                                @TotalAlterados,
                                ', Novos: ',
                                @TotalNovosIdx
                            );
                RAISERROR(@LogMensagem, 0, 1) WITH NOWAIT;
            END;

         

            -- Execução de criação de novos índices
            IF EXISTS (SELECT 1 FROM #NovosIndices)
               AND @Efetivar = 1
            BEGIN
                DECLARE @ContadorNovos INT = 1;
                DECLARE @TotalNovos INT =
                        (
                            SELECT COUNT(*)FROM #NovosIndices WHERE CreateIndex IS NOT NULL
                        );
                DECLARE @ScriptNovo NVARCHAR(1000);

                WHILE @ContadorNovos <= @TotalNovos
                BEGIN
                    SELECT @ScriptNovo = CreateIndex
                    FROM
                    (
                        SELECT CreateIndex,
                               ROW_NUMBER() OVER (ORDER BY ObjectId) AS RowNum
                        FROM #NovosIndices
                        WHERE CreateIndex IS NOT NULL
                    ) t
                    WHERE RowNum = @ContadorNovos;

                    IF @ScriptNovo IS NOT NULL
                    BEGIN
                        EXEC sys.sp_executesql @ScriptNovo;

                        IF @ModoDebug = 1
                        BEGIN
                            SELECT @LogMensagem
                                = N'Índice criado (' + CAST(@ContadorNovos AS VARCHAR(10)) + N'/'
                                  + CAST(@TotalNovos AS VARCHAR(10)) + N')';
                            RAISERROR(@LogMensagem, 0, 1) WITH NOWAIT;
                        END;
                    END;

                    SET @ContadorNovos = @ContadorNovos + 1;
                END;
            END;

            -- Execução de alterações de índices existentes
            IF EXISTS (SELECT 1 FROM #Alteracoes)
               AND @Efetivar = 1
            BEGIN
                DECLARE @ContadorAlteracoes INT = 1;
                DECLARE @TotalAlteracoes INT =
                        (
                            SELECT COUNT(*)
                            FROM #Alteracoes
                            WHERE ScriptDrop IS NOT NULL
                                  AND CreateIndex IS NOT NULL
                        );
                DECLARE @ScriptDrop NVARCHAR(1000);
                DECLARE @ScriptCreate NVARCHAR(1000);

                WHILE @ContadorAlteracoes <= @TotalAlteracoes
                BEGIN
                    SELECT @ScriptDrop = ScriptDrop,
                           @ScriptCreate = CreateIndex
                    FROM
                    (
                        SELECT ScriptDrop,
                               CreateIndex,
                               ROW_NUMBER() OVER (ORDER BY ObjectId) AS RowNum
                        FROM #Alteracoes
                        WHERE ScriptDrop IS NOT NULL
                              AND CreateIndex IS NOT NULL
                    ) t
                    WHERE RowNum = @ContadorAlteracoes;

                    IF @ScriptDrop IS NOT NULL
                       AND @ScriptCreate IS NOT NULL
                    BEGIN
                        EXEC sys.sp_executesql @ScriptDrop;
                        EXEC sys.sp_executesql @ScriptCreate;

                        IF @ModoDebug = 1
                        BEGIN
                            SELECT @LogMensagem
                                = N'Índice alterado (' + CAST(@ContadorAlteracoes AS VARCHAR(10)) + N'/'
                                  + CAST(@TotalAlteracoes AS VARCHAR(10)) + N')';
                            RAISERROR(@LogMensagem, 0, 1) WITH NOWAIT;
                        END;
                    END;

                    SET @ContadorAlteracoes = @ContadorAlteracoes + 1;
                END;
            END;
        END;

        IF (@VisualizarMissing = 1)
        BEGIN
            SELECT 'Missings' AS Sugestao,
                   MI.ObjectId,
                   MI.TotalObjectId,
                   MI.SchemaName,
                   MI.TableName,
                   MI.IndexName,
                   MI.KeyColumns,
                   MI.FirstKeyColumn,
                   MI.ExistsIndexOnKey,
                   MI.KeyBelongsToOtherIndex,
                   MI.IncludedColumns,
                   MI.AvgEstimatedImpact,
                   MI.MagicBenefitNumber,
                   MI.PotentialReadOperations,
                   MI.TotalReads,
                   MI.WriteReadRatioPercent,
                   MI.Priority,
                   MI.CreateIndexScript,
                   IOT.ObjectId,
                   IOT.QuantidadeIndiceTabela
            FROM #MissingIndex MI
                JOIN #InformacaoesOnTable AS IOT
                    ON MI.ObjectId = IOT.ObjectId;
        END;

        IF (@VisualizarCreate = 1)
        BEGIN
            SELECT 'Create' AS Sugestao,
                   NI.RowId,
                   NI.ObjectId,
                   NI.SchemaName,
                   NI.TableName,
                   NI.QuantidadeIndiceTabela,
                   NI.IndexName,
                   NI.Chave,
                   NI.PrimeiraChave,
                   NI.ExisteIndiceNaChave,
                   NI.ChavePertenceAOutroIndice,
                   NI.ColunaIncluida,
                   NI.AvgEstimatedImpact,
                   NI.MagicBenefitNumber,
                   NI.PotentialReadOp,
                   NI.reads,
                   PercCustoMedio = NI.PercCusto,
                   NI.CreateIndex,
                   PercScan = NI.AvgPercScan
            FROM #NovosIndices AS NI;
        END;

        IF (@VisualizarAlteracoes = 1)
        BEGIN
            SELECT 'Alteracao' AS Sugestao,
                   A.RowId,
                   A.ObjectId,
                   A.SchemaName,
                   A.TableName,
                   A.Chave,
                   A.PrimeiraChave,
                   A.ColunaIncluida,
                   A.CreateIndex,
                   A.MagicBenefitNumber,
                   A.Melhor,
                   A.ScriptDrop,
                   A.ScriptCreate
            FROM #Alteracoes AS A;
        END;
    END TRY
    BEGIN CATCH
        IF (@@TRANCOUNT > 0)
            ROLLBACK TRANSACTION;

        DECLARE @ErrorNumber INT = ERROR_NUMBER();
        DECLARE @ErrorLine INT = ERROR_LINE();
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        PRINT 'Actual error number: ' + CAST(@ErrorNumber AS VARCHAR(MAX));
        PRINT 'Actual line number: ' + CAST(@ErrorLine AS VARCHAR(MAX));
        PRINT '@ErrorMessage: ' + CAST(@ErrorMessage AS VARCHAR(MAX));
        PRINT '@ErrorSeverity: ' + CAST(@ErrorLine AS VARCHAR(MAX));
        PRINT '@ErrorState: ' + CAST(@ErrorLine AS VARCHAR(MAX));

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);

        PRINT 'Error detected, all changes reversed.';
    END CATCH;
END;
GO
