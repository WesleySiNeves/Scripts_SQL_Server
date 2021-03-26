

/* ==================================================================
--Data: 23/02/2021 
--Autor :Wesley Neves
--Observação: Sugestões de leitura
 
 https://www.sqlskills.com/blogs/erin/query-store-settings/
https://docs.microsoft.com/pt-br/sql/relational-databases/performance/monitoring-performance-by-using-the-query-store?view=sql-server-ver15
https://docs.microsoft.com/pt-br/sql/relational-databases/performance/best-practice-with-the-query-store?view=sql-server-ver15
https://docs.microsoft.com/pt-br/sql/t-sql/statements/alter-database-transact-sql-set-options?view=sql-server-ver15
-- ==================================================================
*/
/* ==================================================================

--Observação: Tamanho Máximo (MB): especifica o limite para o espaço de dados que o Repositório de
 Consultas admitirá em seu banco de dados. Essa é a configuração mais importante, que afeta diretamente
  o modo de operação do Repositório de Consultas.

Conforme o Repositório de Consultas coleta consultas, planos de execução e estatísticas, 
seu tamanho no banco de dados cresce até esse limite ser atingido. Quando isso acontece,
 o Repositório de Consultas automaticamente altera o modo de operação para somente leitura e para de coletar novos dados, o que significa que a análise de desempenho não é mais precisa.

O valor padrão (100 MB) pode não ser suficiente se sua carga de trabalho gerar muitos e planos
 e consultas diferentes, ou caso você deseje manter o histórico de consulta por um período de tempo maior. Controle o uso de espaço atual e aumente o Tamanho Máximo (MB) para impedir que o Repositório de Consultas passe para o modo somente leitura. Use Management Studio ou execute o script a seguir para obter as informações mais recentes sobre o tamanho do Repositório de Consultas
 
-- ==================================================================
*/

DECLARE @IsAzure BIT = IIF(@@VERSION LIKE '%Azure%', 1, 0);
DECLARE @query VARCHAR(1000);
DECLARE @db_name VARCHAR(1000) = DB_NAME();

--ALTER DATABASE [15-1implanta] SET QUERY_STORE CLEAR;
IF(@IsAzure = 1)
    BEGIN
        SET @query = CONCAT('ALTER DATABASE [', @db_name, '] SET QUERY_STORE = ON
    (
      OPERATION_MODE = READ_WRITE,
      CLEANUP_POLICY = ( STALE_QUERY_THRESHOLD_DAYS = 30 ),
      DATA_FLUSH_INTERVAL_SECONDS = 900,
      MAX_STORAGE_SIZE_MB = 300,
      INTERVAL_LENGTH_MINUTES = 15,
      SIZE_BASED_CLEANUP_MODE = AUTO,
      MAX_PLANS_PER_QUERY = 20,
      WAIT_STATS_CAPTURE_MODE = ON,
      QUERY_CAPTURE_MODE = CUSTOM,
      QUERY_CAPTURE_POLICY = (
        STALE_CAPTURE_POLICY_THRESHOLD = 1 HOUR,
        EXECUTION_COUNT = 100,
        TOTAL_COMPILE_CPU_TIME_MS = 1000,    --1 Segundo
        TOTAL_EXECUTION_CPU_TIME_MS = 1000  --10 segundos
      )
    );');
    END;
ELSE
    BEGIN
        SET @query = CONCAT('ALTER DATABASE ', @db_name, ' SET QUERY_STORE = ON
    (
      OPERATION_MODE = READ_WRITE,
      CLEANUP_POLICY = ( STALE_QUERY_THRESHOLD_DAYS = 30 ),
      DATA_FLUSH_INTERVAL_SECONDS = 900,
      MAX_STORAGE_SIZE_MB = 300,
      INTERVAL_LENGTH_MINUTES = 15,
      SIZE_BASED_CLEANUP_MODE = AUTO,
      MAX_PLANS_PER_QUERY = 20,
      WAIT_STATS_CAPTURE_MODE = ON,
      QUERY_CAPTURE_MODE = AUTO
      
    );');
    END;

EXEC(@query);

SELECT DQSO.actual_state_desc AS ModoAtual,
       DQSO.readonly_reason,
       DQSO.current_storage_size_mb AS TamanhoAtual,
       DQSO.max_storage_size_mb AS TamanhoMaximo,
       flush_interval_Minutos = DQSO.flush_interval_seconds / 60,
       DQSO.interval_length_minutes [Intervalo de Coleta de Estatísticas],
       DQSO.stale_query_threshold_days [Limite de Consulta Obsoleta (Dias)],
       DQSO.size_based_cleanup_mode_desc,
       DQSO.max_plans_per_query
  FROM sys.database_query_store_options AS DQSO;