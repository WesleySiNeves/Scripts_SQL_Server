
/*
==============================================================================
FUNÇÃO: HealthCheck.StatsOnTables
DESCRIÇÃO: Retorna informações detalhadas sobre estatísticas automáticas das tabelas
AUTOR: Wesley
DATA CRIAÇÃO: [Data]
VERSÃO: 2.0 - Melhorada com comentários e campos adicionais
==============================================================================
PARÂMETROS:
    @object_id INT - ID do objeto da tabela (NULL para todas as tabelas)
    
EXEMPLOS DE USO:
    -- Todas as tabelas
    SELECT * FROM HealthCheck.StatsOnTables(NULL)
    
    -- Tabela específica
    SELECT * FROM HealthCheck.StatsOnTables(OBJECT_ID('dbo.MinhaTabela'))
    
    -- Estatísticas desatualizadas (mais de 20% de modificações)
    SELECT * FROM HealthCheck.StatsOnTables(NULL) 
    WHERE modification_counter > (rows * 0.20)
==============================================================================
*/

CREATE OR ALTER FUNCTION HealthCheck.StatsOnTables(@object_id INT)
RETURNS TABLE
AS
RETURN 
(
    SELECT 
        -- Identificação da tabela e estatística
        st.object_id,
        sh.name AS schema_name,
        tab.name AS table_name,
        st.name AS stats_name,
        st.stats_id,
        
        -- Informações da coluna
        sc.stats_column_id,
        co.name AS column_name,
        co.system_type_id,
        TYPE_NAME(co.system_type_id) AS column_type,
        
        -- Propriedades das estatísticas
        st.auto_created,
        st.user_created,
        st.no_recompute,
        st.has_filter,
        st.filter_definition,
        
        -- Dados das estatísticas (sys.dm_db_stats_properties)
        Sta.rows,
        Sta.rows_sampled,
        Sta.last_updated,
        Sta.modification_counter,
        Sta.steps AS histogram_steps,
        Sta.unfiltered_rows,
        
        -- Cálculos úteis para análise
        CASE 
            WHEN Sta.rows > 0 
            THEN CAST((Sta.modification_counter * 100.0 / Sta.rows) AS DECIMAL(10,2))
            ELSE 0 
        END AS modification_percentage,
        
        CASE 
            WHEN Sta.rows > 0 
            THEN CAST((Sta.rows_sampled * 100.0 / Sta.rows) AS DECIMAL(10,2))
            ELSE 0 
        END AS sample_percentage,
        
        DATEDIFF(DAY, Sta.last_updated, GETDATE()) AS days_since_update,
        
        -- Status da estatística
        CASE 
            WHEN Sta.modification_counter > (Sta.rows * 0.20) THEN 'Desatualizada (>20%)'
            WHEN Sta.modification_counter > (Sta.rows * 0.10) THEN 'Atenção (>10%)'
            WHEN DATEDIFF(DAY, Sta.last_updated, GETDATE()) > 7 THEN 'Antiga (>7 dias)'
            ELSE 'OK'
        END AS status_estatistica
        
    FROM 
        sys.stats st
    INNER JOIN 
        sys.tables tab ON st.object_id = tab.object_id
    INNER JOIN 
        sys.schemas sh ON tab.schema_id = sh.schema_id 
    INNER JOIN 
        sys.stats_columns sc ON st.object_id = sc.object_id AND st.stats_id = sc.stats_id
    INNER JOIN 
        sys.columns co ON tab.object_id = co.object_id AND sc.column_id = co.column_id
    CROSS APPLY 
        sys.dm_db_stats_properties(tab.object_id, st.stats_id) AS Sta
    WHERE 
        -- Filtro por tabela específica ou todas as tabelas
        (tab.object_id = @object_id OR @object_id IS NULL)
        -- Apenas estatísticas criadas automaticamente
        AND st.auto_created = 1
        -- Excluir tabelas do sistema
        AND tab.is_ms_shipped = 0
);

