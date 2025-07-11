/*
==============================================================================
Nome: HealthCheck.uspMissingIndex_Optimized
Descrição: Versão otimizada da procedure para análise de índices em falta
Autor: Wesley
Data Criação: 2024
Versão: 2.0 (Otimizada)

Funcionalidade:
- Identifica índices em falta baseado nas DMVs do SQL Server
- Calcula métricas de benefício e impacto
- Gera scripts CREATE INDEX prontos para uso
- Analisa conflitos com índices existentes

Parâmetros:
@defaultTunningPerform: Threshold mínimo para considerar um índice benéfico (padrão: 1000)
@SchemaFilter: Filtro opcional por schema específico
@TableFilter: Filtro opcional por tabela específica
==============================================================================
*/

--SET QUOTED_IDENTIFIER ON;
--SET ANSI_NULLS ON;
--GO

CREATE OR ALTER PROCEDURE HealthCheck.uspMissingIndex
(
    @defaultTunningPerform SMALLINT = 1000,
    @SchemaFilter VARCHAR(128) = NULL,
    @TableFilter VARCHAR(128) = NULL
)
AS
BEGIN


    --DECLARE   @defaultTunningPerform SMALLINT = 1000,
    --    @SchemaFilter VARCHAR(128) = NULL,
    --    @TableFilter VARCHAR(128) = NULL;


    -- Configurações iniciais para melhor performance
    SET NOCOUNT ON;
    SET TRAN ISOLATION LEVEL READ UNCOMMITTED; -- Para análise sem impacto em locks

    BEGIN TRY
        -- Validação dos parâmetros de entrada
        IF @defaultTunningPerform <= 0
           OR @defaultTunningPerform > 100000
        BEGIN
            RAISERROR('Parâmetro @defaultTunningPerform deve estar entre 1 e 100000', 16, 1);
            RETURN;
        END;

        -- Verificação de permissões necessárias
        IF NOT EXISTS
        (
            SELECT 1
            FROM sys.fn_my_permissions(NULL, 'SERVER')
            WHERE permission_name = 'VIEW SERVER STATE'
        )
        BEGIN
            RAISERROR('Usuário não possui permissão VIEW SERVER STATE necessária', 16, 1);
            RETURN;
        END;

        -- Constantes para melhor legibilidade
        DECLARE @MAGIC_MULTIPLIER_HIGH INT = 10;
        DECLARE @MAGIC_MULTIPLIER_VERY_HIGH INT = 20;
        DECLARE @READ_OP_DIVISOR DECIMAL(5, 2) = 20.0;
        DECLARE @BAD_WRITE_READ_RATIO DECIMAL(3, 2) = 1.0;

        -- Limpeza de tabelas temporárias (caso existam de execução anterior)
        DROP TABLE IF EXISTS #Retorno;
        DROP TABLE IF EXISTS #IndexUsage;
        DROP TABLE IF EXISTS #Missings;
        DROP TABLE IF EXISTS #Candidates;
        DROP TABLE IF EXISTS #FirstResultIntermediate; -- Corrigido nome
        DROP TABLE IF EXISTS #SecondResultIntermediate;
        DROP TABLE IF EXISTS #Final;

        -- Criação da tabela de resultado final
        CREATE TABLE #Retorno
        (
            ObjectId INT,
            TotalObjectId INT,                    -- Corrigido nome
            SchemaName VARCHAR(140),
            TableName VARCHAR(140),
            IndexName VARCHAR(200),
            KeyColumns VARCHAR(200),              -- Nome mais descritivo
            FirstKeyColumn VARCHAR(200),          -- Nome mais descritivo
            ExistsIndexOnKey INT,
            KeyBelongsToOtherIndex INT,
            IncludedColumns VARCHAR(1000),
            AvgEstimatedImpact REAL,
            MagicBenefitNumber REAL,
            PotentialReadOperations INT,          -- Nome mais descritivo
            TotalReads INT,
            WriteReadRatioPercent DECIMAL(10, 2), -- Nome mais descritivo
            Priority VARCHAR(10),                 -- Nova coluna para prioridade
            CreateIndexScript VARCHAR(8000)
        );

        -- Tabela para armazenar estatísticas de uso dos índices
        CREATE TABLE #IndexUsage
        (
            object_id INT,
            index_id TINYINT,
            user_seeks INT,
            user_scans INT,
            user_lookups INT,
            user_updates INT,
            PRIMARY KEY (
                            object_id,
                            index_id
                        )
        );

        -- Índice para melhorar performance dos JOINs
        CREATE INDEX IX_IndexUsage_ObjectId ON #IndexUsage (object_id);

        -- Tabela para índices em falta identificados pelo SQL Server
        CREATE TABLE #Missings
        (
            object_id INT,
            SchemaName VARCHAR(140) COLLATE DATABASE_DEFAULT,
            ObjectName VARCHAR(140) COLLATE DATABASE_DEFAULT,
            equality_columns VARCHAR(300) COLLATE DATABASE_DEFAULT,
            inequality_columns VARCHAR(300) COLLATE DATABASE_DEFAULT,
            included_columns VARCHAR(1000) COLLATE DATABASE_DEFAULT,
            unique_compiles INT,
            user_seeks INT,
            last_user_seek DATETIME2(3),
            user_scans INT,
            last_user_scan DATETIME2(3),
            IndexName VARCHAR(128) COLLATE DATABASE_DEFAULT,
            AvgEstimatedImpact FLOAT(8),
            MagicBenefitNumber FLOAT(8)
        );

        -- Tabela para candidatos processados
        CREATE TABLE #Candidates
        (
            object_id INT,
            SchemaName VARCHAR(140),
            ObjectName VARCHAR(140),
            equality_columns VARCHAR(300) COLLATE DATABASE_DEFAULT,
            inequality_columns VARCHAR(300) COLLATE DATABASE_DEFAULT,
            included_columns VARCHAR(1000) COLLATE DATABASE_DEFAULT,
            unique_compiles INT,
            user_seeks INT,
            last_user_seek DATETIME2(3),
            user_scans INT,
            last_user_scan DATETIME2(3),
            IndexName VARCHAR(128),
            KeyColumns VARCHAR(200),
            FirstKeyColumn AS
                (IIF(CHARINDEX(',', KeyColumns, 0) > 0,
                     SUBSTRING(KeyColumns, 0, CHARINDEX(',', KeyColumns, 0)),
                     KeyColumns)
                ),
            IncludedColumns VARCHAR(1000) COLLATE DATABASE_DEFAULT,
            AvgEstimatedImpact REAL,
            MagicBenefitNumber REAL
        );

        -- Índices para melhorar performance
        CREATE INDEX IX_Candidates_ObjectId ON #Candidates (object_id);
        CREATE INDEX IX_Candidates_ObjectId_FirstKey
        ON #Candidates (
                           object_id,
                           FirstKeyColumn
                       );

        -- Tabelas intermediárias para processamento
        CREATE TABLE #FirstResultIntermediate
        (
            object_id INT,
            SchemaName VARCHAR(140) COLLATE DATABASE_DEFAULT,
            ObjectName VARCHAR(140) COLLATE DATABASE_DEFAULT,
            user_seeks INT,
            user_scans INT,
            unique_compiles INT,
            IndexName VARCHAR(200),
            KeyColumns VARCHAR(200),
            FirstKeyColumn VARCHAR(200) COLLATE DATABASE_DEFAULT,
            IncludedColumns VARCHAR(1000) COLLATE DATABASE_DEFAULT,
            AvgEstimatedImpact REAL,
            MagicBenefitNumber REAL,
            PotentialReadOperations INT,
            TotalReads INT,
            WriteReadRatio DECIMAL(10, 2)
        );

        CREATE TABLE #SecondResultIntermediate
        (
            object_id INT,
            user_seeks INT,
            user_scans INT,
            unique_compiles INT,
            IndexName VARCHAR(200) COLLATE DATABASE_DEFAULT,
            KeyColumns VARCHAR(200) COLLATE DATABASE_DEFAULT,
            FirstKeyColumn VARCHAR(200) COLLATE DATABASE_DEFAULT,
            IncludedColumns VARCHAR(1000) COLLATE DATABASE_DEFAULT,
            AvgEstimatedImpact REAL,
            MagicBenefitNumber REAL,
            CountObjectId INT,
            CountObjectIdAndKey INT,
            TotalMagicBenefitNumber FLOAT(8),
            MaxMagicBenefitNumber REAL,
            TotalAvgEstimatedImpact FLOAT(8),
            MaxAvgEstimatedImpact REAL
        );

        CREATE TABLE #Final
        (
            object_id INT,
            SchemaName VARCHAR(140),
            ObjectName VARCHAR(140),
            user_seeks INT,
            user_scans INT,
            unique_compiles INT,
            IndexName VARCHAR(200),
            KeyColumns VARCHAR(200),
            FirstKeyColumn VARCHAR(200),
            IncludedColumns VARCHAR(1000),
            AvgEstimatedImpact REAL,
            MagicBenefitNumber REAL,
            PotentialReadOperations INT,
            TotalReads INT,
            WriteReadRatio DECIMAL(10, 2)
        );

        -- 1. COLETA DE DADOS: Estatísticas de uso dos índices existentes
        INSERT INTO #IndexUsage
        SELECT s.object_id,
               s.index_id,
               s.user_seeks,
               s.user_scans,
               s.user_lookups,
               s.user_updates
        FROM sys.dm_db_index_usage_stats AS s
        WHERE s.database_id = DB_ID();

        -- 2. COLETA DE DADOS: Índices em falta das DMVs
        WITH MissingIndexData
        AS (SELECT dm_mid.object_id,
                   SchemaName = CAST(OBJECT_SCHEMA_NAME(dm_mid.object_id) AS VARCHAR(128)) COLLATE DATABASE_DEFAULT,
                   ObjectName = CAST(OBJECT_NAME(dm_mid.object_id) AS VARCHAR(128)) COLLATE DATABASE_DEFAULT,
                   CAST(dm_mid.equality_columns AS VARCHAR(300)) equality_columns,
                   CAST(dm_mid.inequality_columns AS VARCHAR(300)) inequality_columns,
                   CAST(dm_mid.included_columns AS VARCHAR(1000)) included_columns,
                   dm_migs.unique_compiles,
                   dm_migs.user_seeks,
                   dm_migs.last_user_seek,
                   dm_migs.user_scans,
                   dm_migs.last_user_scan,
                   -- Geração automática do nome do índice
                   IndexName = CAST('IX_'
                                    + CAST(OBJECT_SCHEMA_NAME(dm_mid.object_id, dm_mid.database_id) AS VARCHAR(400)) COLLATE DATABASE_DEFAULT
                                    + OBJECT_NAME(dm_mid.object_id, dm_mid.database_id) + '_'
                                    + REPLACE(
                                                 REPLACE(
                                                            REPLACE(ISNULL(dm_mid.equality_columns, ''), ', ', '_'),
                                                            '[',
                                                            ''
                                                        ),
                                                 ']',
                                                 ''
                                             ) + CASE
                                                     WHEN dm_mid.equality_columns IS NOT NULL
                                                          AND dm_mid.inequality_columns IS NOT NULL THEN
                                                         CAST('_' AS VARCHAR(1))
                                                     ELSE
                                                         CAST('' AS VARCHAR(1))
                                                 END
                                    + REPLACE(
                                                 REPLACE(
                                                            REPLACE(
                                                                       ISNULL(
                                                                                 dm_mid.inequality_columns COLLATE DATABASE_DEFAULT,
                                                                                 CAST('' AS VARCHAR(1))
                                                                             ),
                                                                       ', ',
                                                                       '_'
                                                                   ),
                                                            '[',
                                                            CAST('' AS VARCHAR(1))
                                                        ),
                                                 ']',
                                                 CAST('' AS VARCHAR(1))
                                             ) AS VARCHAR(128))COLLATE DATABASE_DEFAULT,
                   -- Cálculo do impacto estimado
                   AvgEstimatedImpact = dm_migs.avg_user_impact * (dm_migs.user_seeks + dm_migs.user_scans),
                   -- Número mágico de benefício (fórmula padrão do SQL Server)
                   MagicBenefitNumber = dm_migs.avg_total_user_cost * dm_migs.avg_user_impact
                                        * (dm_migs.user_seeks + dm_migs.user_scans)
            FROM sys.dm_db_missing_index_details AS dm_mid
                INNER JOIN sys.dm_db_missing_index_groups AS dm_mig
                    ON dm_mid.index_handle = dm_mig.index_handle
                INNER JOIN sys.dm_db_missing_index_group_stats AS dm_migs
                    ON dm_mig.index_group_handle = dm_migs.group_handle
            WHERE dm_mid.database_id = DB_ID()
                  -- Aplicar filtros se especificados
                  AND
                  (
                      @SchemaFilter IS NULL
                      OR OBJECT_SCHEMA_NAME(dm_mid.object_id) = @SchemaFilter
                  )
                  AND
                  (
                      @TableFilter IS NULL
                      OR OBJECT_NAME(dm_mid.object_id) = @TableFilter
                  ))
        INSERT INTO #Missings
        SELECT object_id,
               SchemaName,
               ObjectName,
               equality_columns,
               inequality_columns,
               included_columns,
               unique_compiles,
               user_seeks,
               last_user_seek,
               user_scans,
               last_user_scan,
               IndexName,
               AvgEstimatedImpact,
               MagicBenefitNumber
        FROM MissingIndexData;


        -- 3. PROCESSAMENTO: Apenas se existem índices em falta
        IF EXISTS (SELECT 1 FROM #Missings)
        BEGIN
            -- Criar função temporária para filtrar colunas inválidas
            DECLARE @CreateFilterFunction NVARCHAR(MAX) = '
            CREATE OR ALTER FUNCTION dbo.fnFilterInvalidIndexColumns(
                @ColumnList VARCHAR(8000),
                @ObjectId INT
            )
            RETURNS VARCHAR(8000)
            AS
            BEGIN
                DECLARE @FilteredColumns VARCHAR(8000) = '''';
                DECLARE @CurrentColumn VARCHAR(128);
                DECLARE @Position INT = 1;
                DECLARE @CommaPosition INT;
                
                -- Se a lista está vazia, retorna vazio
                IF @ColumnList IS NULL OR LEN(TRIM(@ColumnList)) = 0
                    RETURN '''';
                
                -- Adicionar vírgula no final para facilitar o processamento
                SET @ColumnList = @ColumnList + '','';
                
                WHILE @Position <= LEN(@ColumnList)
                BEGIN
                    SET @CommaPosition = CHARINDEX('','', @ColumnList, @Position);
                    
                    IF @CommaPosition > 0
                    BEGIN
                        SET @CurrentColumn = LTRIM(RTRIM(SUBSTRING(@ColumnList, @Position, @CommaPosition - @Position)));
                        
                        -- Verificar se a coluna é válida para índice
                        IF EXISTS (
                            SELECT 1
                            FROM sys.columns c
                            JOIN sys.types t ON c.user_type_id = t.user_type_id
                            WHERE c.object_id = @ObjectId
                                AND c.name = @CurrentColumn
                                AND NOT (
                                    (t.name = ''varchar'' AND c.max_length = -1) OR
                                    (t.name = ''nvarchar'' AND c.max_length = -1) OR
                                    (t.name = ''varbinary'' AND c.max_length = -1) OR
                                    t.name = ''text'' OR
                                    t.name = ''ntext'' OR
                                    t.name = ''image''
                                )
                        )
                        BEGIN
                            IF LEN(@FilteredColumns) > 0
                                SET @FilteredColumns = @FilteredColumns + '','';
                            SET @FilteredColumns = @FilteredColumns + @CurrentColumn;
                        END
                        
                        SET @Position = @CommaPosition + 1;
                    END
                    ELSE
                        BREAK;
                END
                
                RETURN @FilteredColumns;
            END';
            
            -- Executar criação da função
             EXEC sp_executesql @CreateFilterFunction;

             -- Processamento dos candidatos com filtragem de colunas inválidas
            WITH ProcessedCandidates
            AS (SELECT R.object_id,
                       R.SchemaName,
                       R.ObjectName,
                       R.equality_columns,
                       R.inequality_columns,
                       R.included_columns,
                       R.unique_compiles,
                       R.user_seeks,
                       R.last_user_seek,
                       R.user_scans,
                       R.last_user_scan,
                       R.IndexName,
                       -- Combinação das colunas chave (equality + inequality) com filtragem
                       KeyColumns = CAST(LTRIM(RTRIM(
                           -- Filtrar colunas inválidas das KeyColumns
                           dbo.fnFilterInvalidIndexColumns(
                               REPLACE(
                                   REPLACE(
                                       REPLACE(
                                           ISNULL(R.equality_columns, '')
                                           + CASE
                                               WHEN R.equality_columns IS NOT NULL
                                                    AND R.inequality_columns IS NOT NULL THEN
                                                   ','
                                               ELSE
                                                   ''
                                           END
                                           + ISNULL(R.inequality_columns, ''),
                                           CHAR(32),
                                           ''
                                       ),
                                       '[',
                                       ''
                                   ),
                                   ']',
                                   ''
                               ),
                               R.object_id
                           )
                       )) AS VARCHAR(200)),
                       -- Limpeza das colunas incluídas com filtragem
                       IncludedColumns = CAST(LTRIM(RTRIM(
                           -- Filtrar colunas inválidas das IncludedColumns
                           dbo.fnFilterInvalidIndexColumns(
                               REPLACE(
                                   REPLACE(
                                       REPLACE(
                                           R.included_columns,
                                           '[',
                                           CHAR(32)
                                       ),
                                       ']',
                                       CHAR(32)
                                   ),
                                   CHAR(32),
                                   ''
                               ),
                               R.object_id
                           )
                       )) AS VARCHAR(1000)),
                       R.AvgEstimatedImpact,
                       R.MagicBenefitNumber
                FROM #Missings R)
            INSERT INTO #Candidates
            SELECT object_id,
                   SchemaName,
                   ObjectName,
                   equality_columns,
                   inequality_columns,
                   included_columns,
                   unique_compiles,
                   user_seeks,
                   last_user_seek,
                   user_scans,
                   last_user_scan,
                   IndexName,
                   KeyColumns,
                   IncludedColumns,
                   AvgEstimatedImpact,
                   MagicBenefitNumber
            FROM ProcessedCandidates
            WHERE LEN(LTRIM(RTRIM(KeyColumns))) > 0; -- Só incluir se ainda há colunas válidas após filtragem

            -- Limpar função temporária
            IF OBJECT_ID('dbo.fnFilterInvalidIndexColumns', 'FN') IS NOT NULL
                DROP FUNCTION dbo.fnFilterInvalidIndexColumns;

            -- 4. ANÁLISE: Objetos com apenas um candidato (casos simples)
            WITH SingleCandidateAnalysis
            AS (SELECT C.object_id,
                       C.SchemaName,
                       C.ObjectName,
                       C.user_seeks,
                       C.user_scans,
                       C.unique_compiles,
                       C.IndexName,
                       C.KeyColumns,
                       C.FirstKeyColumn,
                       C.IncludedColumns,
                       C.AvgEstimatedImpact,
                       C.MagicBenefitNumber,
                       CountObjectId = COUNT(C.object_id) OVER (PARTITION BY C.object_id)
                FROM #Candidates AS C),
                 SingleCandidateWithStats
            AS (SELECT A.object_id,
                       A.SchemaName,
                       A.ObjectName,
                       A.user_seeks,
                       A.user_scans,
                       A.unique_compiles,
                       A.IndexName,
                       A.KeyColumns,
                       A.FirstKeyColumn,
                       A.IncludedColumns,
                       A.CountObjectId,
                       A.AvgEstimatedImpact,
                       A.MagicBenefitNumber,
                       PotentialReadOperations = (I.user_seeks + I.user_scans),
                       TotalReads = (I.user_seeks + I.user_scans + I.user_lookups),
                       WriteReadRatio = CAST((I.user_updates * 1.0
                                              / NULLIF(I.user_scans + I.user_seeks + I.user_lookups, 0)
                                             ) AS DECIMAL(10, 2))
                FROM SingleCandidateAnalysis A
                    JOIN
                    (
                        SELECT I.object_id,
                               SUM(I.user_seeks) user_seeks,
                               SUM(I.user_scans) user_scans,
                               SUM(I.user_lookups) user_lookups,
                               SUM(I.user_updates) user_updates
                        FROM #IndexUsage AS I
                        GROUP BY I.object_id
                    ) AS I
                        ON A.object_id = I.object_id)
            INSERT INTO #FirstResultIntermediate
            SELECT object_id,
                   SchemaName,
                   ObjectName,
                   user_seeks,
                   user_scans,
                   unique_compiles,
                   IndexName,
                   KeyColumns,
                   FirstKeyColumn,
                   IncludedColumns,
                   AvgEstimatedImpact,
                   MagicBenefitNumber,
                   PotentialReadOperations,
                   TotalReads,
                   WriteReadRatio
            FROM SingleCandidateWithStats
            WHERE CountObjectId = 1;

			
            -- 5. FILTRAGEM: Aplicar critérios de qualidade para casos simples
            INSERT INTO #Final
            SELECT object_id,
                   SchemaName,
                   ObjectName,
                   user_seeks,
                   user_scans,
                   unique_compiles,
                   IndexName,
                   KeyColumns,
                   FirstKeyColumn,
                   IncludedColumns,
                   AvgEstimatedImpact,
                   MagicBenefitNumber,
                   PotentialReadOperations,
                   TotalReads,
                   WriteReadRatio
            FROM #FirstResultIntermediate
            WHERE (
                      -- Critério principal: ambos os valores devem ser altos
                      (
                          MagicBenefitNumber >= @defaultTunningPerform
                          
                      )
                      OR
                      -- Critério alternativo: benefício muito alto com boa relação leitura/escrita
                      (
                          MagicBenefitNumber >= @defaultTunningPerform * @MAGIC_MULTIPLIER_HIGH
                          AND WriteReadRatio < @BAD_WRITE_READ_RATIO
                          AND PotentialReadOperations > (@defaultTunningPerform / @READ_OP_DIVISOR)
                      )
                  );
				 

            -- Remove candidatos já processados
            DELETE FROM #Candidates
            WHERE object_id IN
                  (
                      SELECT object_id FROM #FirstResultIntermediate
                  );

            TRUNCATE TABLE #FirstResultIntermediate;

            -- 6. ANÁLISE: Objetos com múltiplos candidatos (casos complexos)
            WITH MultipleCandidateAnalysis
            AS (SELECT C.object_id,
                       C.user_seeks,
                       C.SchemaName,
                       C.ObjectName,
                       C.user_scans,
                       C.unique_compiles,
                       C.IndexName,
                       C.KeyColumns,
                       C.FirstKeyColumn,
                       C.IncludedColumns,
                       C.AvgEstimatedImpact,
                       C.MagicBenefitNumber,
                       CountObjectId = COUNT(*) OVER (PARTITION BY C.object_id),
                       CountObjectIdAndKey = COUNT(*) OVER (PARTITION BY C.object_id, C.FirstKeyColumn),
                       -- Agregações por chave para identificar o melhor candidato
                       TotalMagicBenefitNumber = SUM(C.MagicBenefitNumber) OVER (PARTITION BY C.object_id, C.FirstKeyColumn),
                       MaxMagicBenefitNumber = MAX(C.MagicBenefitNumber) OVER (PARTITION BY C.object_id, C.FirstKeyColumn),
                       TotalAvgEstimatedImpact = SUM(C.AvgEstimatedImpact) OVER (PARTITION BY C.object_id, C.FirstKeyColumn),
                       MaxAvgEstimatedImpact = MAX(C.AvgEstimatedImpact) OVER (PARTITION BY C.object_id, C.FirstKeyColumn)
                FROM #Candidates AS C),
                 MultipleCandidateWithStats
            AS (SELECT two.object_id,
                       two.ObjectName,
                       two.SchemaName,
                       two.user_seeks,
                       two.user_scans,
                       two.unique_compiles,
                       two.IndexName,
                       two.KeyColumns,
                       two.FirstKeyColumn,
                       two.IncludedColumns,
                       two.AvgEstimatedImpact,
                       two.MagicBenefitNumber,
                       two.CountObjectId,
                       two.CountObjectIdAndKey,
                       two.TotalMagicBenefitNumber,
                       two.MaxMagicBenefitNumber,
                       two.TotalAvgEstimatedImpact,
                       two.MaxAvgEstimatedImpact,
                       PotentialReadOperations = (I.user_seeks + I.user_scans),
                       TotalReads = (I.user_seeks + I.user_scans + I.user_lookups),
                       WriteReadRatio = CAST((I.user_updates * 1.0
                                              / NULLIF(I.user_scans + I.user_seeks + I.user_lookups, 0)
                                             ) AS DECIMAL(10, 2))
                FROM MultipleCandidateAnalysis two
                    JOIN
                    (
                        SELECT I.object_id,
                               SUM(I.user_seeks) user_seeks,
                               SUM(I.user_scans) user_scans,
                               SUM(I.user_lookups) user_lookups,
                               SUM(I.user_updates) user_updates
                        FROM #IndexUsage AS I
                        GROUP BY I.object_id
                    ) AS I
                        ON two.object_id = I.object_id)
            INSERT INTO #Final
            SELECT object_id,
                   SchemaName,
                   ObjectName,
                   user_seeks,
                   user_scans,
                   unique_compiles,
                   IndexName,
                   KeyColumns,
                   FirstKeyColumn,
                   IncludedColumns,
                   AvgEstimatedImpact,
                   MagicBenefitNumber,
                   PotentialReadOperations,
                   TotalReads,
                   WriteReadRatio
            FROM MultipleCandidateWithStats C
            WHERE (
                      -- Critério para múltiplos candidatos: usar totais agregados
                      (
                          TotalMagicBenefitNumber > @defaultTunningPerform
                          AND TotalAvgEstimatedImpact > @defaultTunningPerform
                      )
                      OR
                      (
                          TotalMagicBenefitNumber > (@defaultTunningPerform * @MAGIC_MULTIPLIER_VERY_HIGH)
                          AND WriteReadRatio < @BAD_WRITE_READ_RATIO
                          AND PotentialReadOperations > (@defaultTunningPerform / @READ_OP_DIVISOR)
                      )
                  );

            -- 7. CONSOLIDAÇÃO: Resultado final com análise de conflitos
            WITH FinalConsolidated
            AS (SELECT F.object_id,
                       F.SchemaName,
                       F.ObjectName,
                       F.IndexName,
                       F.KeyColumns,
                       F.FirstKeyColumn,
                       F.IncludedColumns,
                       MAX(F.AvgEstimatedImpact) AvgEstimatedImpact,
                       MAX(F.MagicBenefitNumber) MagicBenefitNumber,
                       MAX(F.PotentialReadOperations) PotentialReadOperations,
                       MAX(F.TotalReads) TotalReads,
                       MAX(F.WriteReadRatio) WriteReadRatio
                FROM #Final AS F
                GROUP BY F.object_id,
                         F.SchemaName,
                         F.ObjectName,
                         F.IndexName,
                         F.KeyColumns,
                         F.FirstKeyColumn,
                         F.IncludedColumns)
            INSERT INTO #Retorno
            SELECT ObjectId = FI.object_id,
                   TotalObjectId = COUNT(*) OVER (PARTITION BY FI.object_id),
                   SchemaName = FI.SchemaName,
                   TableName = FI.ObjectName,
                   IndexName = FI.IndexName,
                   KeyColumns = FI.KeyColumns,
                   FirstKeyColumn = FI.FirstKeyColumn,
                   -- Verificação se já existe índice começando com a mesma coluna
                   ExistsIndexOnKey = CASE
                                          WHEN EXISTS
        (
            SELECT 1
            FROM sys.indexes AS I
                JOIN sys.index_columns AS IC
                    ON I.object_id = IC.object_id
                       AND I.index_id = IC.index_id
                JOIN sys.columns AS C
                    ON I.object_id = C.object_id
                       AND IC.column_id = C.column_id
                       AND IC.is_included_column = 0
            WHERE I.object_id = FI.object_id
                  AND C.name COLLATE DATABASE_DEFAULT = FI.FirstKeyColumn COLLATE DATABASE_DEFAULT
                  AND IC.key_ordinal = 1
        )          THEN
                                              1
                                          ELSE
                                              0
                                      END,
                   -- Verificação se a coluna pertence a outro índice (não como primeira coluna)
                   KeyBelongsToOtherIndex = CASE
                                                WHEN EXISTS
        (
            SELECT 1
            FROM sys.indexes AS I
                JOIN sys.index_columns AS IC
                    ON I.object_id = IC.object_id
                       AND I.index_id = IC.index_id
                JOIN sys.columns AS C
                    ON I.object_id = C.object_id
                       AND IC.column_id = C.column_id
                       AND IC.is_included_column = 0
            WHERE I.object_id = FI.object_id
                  AND C.name COLLATE DATABASE_DEFAULT = FI.FirstKeyColumn
                  AND IC.key_ordinal > 1
        )          THEN
                                                    1
                                                ELSE
                                                    0
                                            END,
                   IncludedColumns = FI.IncludedColumns,
                   AvgEstimatedImpact = FI.AvgEstimatedImpact,
                   MagicBenefitNumber = FI.MagicBenefitNumber,
                   PotentialReadOperations = FI.PotentialReadOperations,
                   TotalReads = FI.TotalReads,
                   WriteReadRatioPercent = FI.WriteReadRatio,
                   -- Cálculo da prioridade baseado nos critérios definidos
                   Priority = CASE
                                  WHEN FI.MagicBenefitNumber > 10000
                                       AND FI.AvgEstimatedImpact > 80
                                       AND FI.WriteReadRatio < 0.1 THEN
                                      'ALTA'
                                  WHEN FI.MagicBenefitNumber
                                       BETWEEN 1000 AND 10000
                                       AND FI.AvgEstimatedImpact
                                       BETWEEN 50 AND 80
                                       AND FI.WriteReadRatio < 1.0 THEN
                                      'MÉDIA'
                                  WHEN FI.MagicBenefitNumber < 1000
                                       OR FI.AvgEstimatedImpact < 50
                                       OR FI.WriteReadRatio > 1.0 THEN
                                      'BAIXA'
                                  ELSE
                                      'MÉDIA' -- Casos que não se encaixam perfeitamente
                              END,
                   -- Script CREATE INDEX otimizado
                   CreateIndexScript = CONCAT(
                                                 'CREATE NONCLUSTERED INDEX ',
                                                 FI.IndexName,
                                                 ' ON ',
                                                 FI.SchemaName,
                                                 '.',
                                                 FI.ObjectName,
                                                 ' (',
                                                 FI.KeyColumns,
                                                 ')',
                                                 IIF(
                                                     FI.IncludedColumns IS NOT NULL
                                                     AND LEN(FI.IncludedColumns) > 0,
                                                     CONCAT(' INCLUDE (', FI.IncludedColumns, ')'),
                                                     ''),
                                                 ' WITH (',
                                                 'FILLFACTOR = 90, ',
                                                 'ONLINE = ON, ',
                                                 'DATA_COMPRESSION = PAGE',
                                                 IIF(
                                                     EXISTS
        (
            SELECT 1
            FROM sys.indexes AS I
            WHERE I.object_id = FI.object_id
                  AND I.name COLLATE DATABASE_DEFAULT = FI.IndexName COLLATE DATABASE_DEFAULT
        ),
                                                     ', DROP_EXISTING = ON',
                                                     ''),
                                                 ');'
                                             )
            FROM FinalConsolidated FI;

            -- 8. RESULTADO: Retorna as recomendações ordenadas por prioridade e benefício
            SELECT ObjectId,
                   TotalObjectId,
                   SchemaName,
                   TableName,
                   IndexName,
                   KeyColumns,
                   FirstKeyColumn,
                   ExistsIndexOnKey,
                   KeyBelongsToOtherIndex,
                   IncludedColumns,
                   AvgEstimatedImpact,
                   MagicBenefitNumber,
                   PotentialReadOperations,
                   TotalReads,
                   WriteReadRatioPercent,
                   Priority,
                   CreateIndexScript
            FROM #Retorno
            ORDER BY CASE Priority
                         WHEN 'ALTA' THEN
                             1
                         WHEN 'MÉDIA' THEN
                             2
                         WHEN 'BAIXA' THEN
                             3
                         ELSE
                             4
                     END,
                     MagicBenefitNumber DESC,
                     AvgEstimatedImpact DESC;

        END;
        ELSE
        BEGIN
            -- Nenhum índice em falta encontrado
            SELECT 'Nenhum índice em falta foi identificado com os critérios especificados.' AS Mensagem;
        END;

    END TRY
    BEGIN CATCH
        -- Tratamento de erros melhorado
        DECLARE @ErrorNumber INT = ERROR_NUMBER();
        DECLARE @ErrorLine INT = ERROR_LINE();
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        DECLARE @ErrorProcedure NVARCHAR(128) = ERROR_PROCEDURE();

        -- Log detalhado do erro
        PRINT '========== ERRO NA EXECUÇÃO DA PROCEDURE ==========';
        PRINT 'Procedure: ' + ISNULL(@ErrorProcedure, 'uspMissingIndex_Optimized');
        PRINT 'Número do Erro: ' + CAST(@ErrorNumber AS VARCHAR(MAX));
        PRINT 'Linha do Erro: ' + CAST(@ErrorLine AS VARCHAR(MAX));
        PRINT 'Mensagem: ' + @ErrorMessage;
        PRINT 'Severidade: ' + CAST(@ErrorSeverity AS VARCHAR(MAX));
        PRINT 'Estado: ' + CAST(@ErrorState AS VARCHAR(MAX));
        PRINT 'Parâmetros: @defaultTunningPerform=' + CAST(@defaultTunningPerform AS VARCHAR(MAX));
        PRINT '==================================================';

        -- Re-lança o erro para o cliente
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);

    END CATCH;
END;
--GO

/*
==============================================================================
EXEMPLOS DE USO:

-- Execução padrão
EXEC HealthCheck.uspMissingIndex_Optimized;

-- Com threshold personalizado
EXEC HealthCheck.uspMissingIndex_Optimized @defaultTunningPerform = 500;

-- Filtrado por schema específico
EXEC HealthCheck.uspMissingIndex_Optimized @SchemaFilter = 'dbo';

-- Filtrado por tabela específica
EXEC HealthCheck.uspMissingIndex_Optimized @TableFilter = 'MinhaTabela';

-- Combinação de filtros
EXEC HealthCheck.uspMissingIndex_Optimized 
    @defaultTunningPerform = 2000,
    @SchemaFilter = 'Sales',
    @TableFilter = 'Orders';
==============================================================================
*/