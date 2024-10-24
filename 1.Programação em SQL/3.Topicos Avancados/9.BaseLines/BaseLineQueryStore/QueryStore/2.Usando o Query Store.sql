

/* ==================================================================
--Data: 23/02/2021 
--Autor :Wesley Neves
--Observa��o: Sugest�es de leitura
 
 https://www.sqlskills.com/blogs/erin/query-store-settings/
https://docs.microsoft.com/pt-br/sql/relational-databases/performance/monitoring-performance-by-using-the-query-store?view=sql-server-ver15
https://docs.microsoft.com/pt-br/sql/relational-databases/performance/best-practice-with-the-query-store?view=sql-server-ver15
https://docs.microsoft.com/pt-br/sql/t-sql/statements/alter-database-transact-sql-set-options?view=sql-server-ver15
-- ==================================================================
*/
/* ==================================================================

--Observa��o: Tamanho M�ximo (MB): especifica o limite para o espa�o de dados que o Reposit�rio de
 Consultas admitir� em seu banco de dados. Essa � a configura��o mais importante, que afeta diretamente
  o modo de opera��o do Reposit�rio de Consultas.

Conforme o Reposit�rio de Consultas coleta consultas, planos de execu��o e estat�sticas, 
seu tamanho no banco de dados cresce at� esse limite ser atingido. Quando isso acontece,
 o Reposit�rio de Consultas automaticamente altera o modo de opera��o para somente leitura e para de coletar novos dados, o que significa que a an�lise de desempenho n�o � mais precisa.

O valor padr�o (100 MB) pode n�o ser suficiente se sua carga de trabalho gerar muitos e planos
 e consultas diferentes, ou caso voc� deseje manter o hist�rico de consulta por um per�odo de tempo maior. Controle o uso de espa�o atual e aumente o Tamanho M�ximo (MB) para impedir que o Reposit�rio de Consultas passe para o modo somente leitura. Use Management Studio ou execute o script a seguir para obter as informa��es mais recentes sobre o tamanho do Reposit�rio de Consultas
 
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
      MAX_STORAGE_SIZE_MB = 1024,
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
       DQSO.interval_length_minutes [Intervalo de Coleta de Estat�sticas],
       DQSO.stale_query_threshold_days [Limite de Consulta Obsoleta (Dias)],
       DQSO.size_based_cleanup_mode_desc,
       DQSO.max_plans_per_query
  FROM sys.database_query_store_options AS DQSO;