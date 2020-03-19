-- ==================================================================
--Observação: Script para habilitar o query store
/* 
ALTER DATABASE <databasename>
SET QUERY_STORE = ON
(
OPERATION_MODE = READ_WRITE ,
CLEANUP_POLICY = ( STALE_QUERY_THRESHOLD_DAYS = 30 ),
DATA_FLUSH_INTERVAL_SECONDS = 3000,
MAX_STORAGE_SIZE_MB = 500,
INTERVAL_LENGTH_MINUTES = 50
);
 */
-- ==================================================================

-- ==================================================================
--Observação: Configuracoes
/*
--1)Data Flush Interval (Minutes) 
A frequência em minutos em que o SQL Server
grava dados coletados pelo armazenamento de consulta em disco.
*/
ALTER DATABASE [15-implanta]
SET QUERY_STORE = ON (DATA_FLUSH_INTERVAL_SECONDS = 3000); --50 minutos;




-- ==================================================================
/* 2)Statistics Collection Interval 
A granularidade do tempo para o qual o SQL Server
agrega estatísticas de execução de tempo de execução para o armazenamento de consulta. Você pode escolher um dos
seguintes intervalos: 1 minuto, 5 minutos, 10 minutos, 15 minutos, 30 minutos, 1 hora,
ou 1 dia. Se você capturar dados com alta frequência, lembre-se de que o armazenamento de consultas
requer mais espaço para armazenar dados mais granulados.
 */
-- ==================================================================
ALTER DATABASE [15-implanta]
SET QUERY_STORE = ON (INTERVAL_LENGTH_MINUTES = 1); -- 1 minuto

-- ==================================================================
/* 3)Max Size (MB)
A quantidade máxima de espaço alocado para o armazenamento de consulta. o
O valor padrão é 100 MB por banco de dados. Se o seu banco de dados estiver ativo, esse valor pode não
ser grande o suficiente para armazenar planos de consulta e informações relacionadas.
 */
-- ==================================================================
ALTER DATABASE [15-implanta]
SET QUERY_STORE = ON (MAX_STORAGE_SIZE_MB = 100); -- 1 100 MB


-- ==================================================================
/* 4) Query Store Capture Mode
A especificação dos tipos de consultas para as quais
O SQL Server captura dados para o repositório de consultas. Você pode escolher um dos seguintes
opções:
 */
-- NONE : O armazenamento de consultas para de coletar dados para novas consultas, mas continua
--captura de dados para consultas existentes.

--All : O armazenamento de consulta captura dados para todas as consultas

--Auto : O armazenamento de consulta captura dados para consultas relevantes. Ignora pouco frequente
--consultas e consultas com duração de compilação e execução insignificantes
-- ==================================================================

ALTER DATABASE [15-implanta]
SET QUERY_STORE = ON (QUERY_CAPTURE_MODE = AUTO); -- 1 100 MB

-- ==================================================================
--Observação:
/* 4) Size Based Cleanup Mode
--A especificação de se o processo de limpeza
--ativa quando os dados de armazenamento de consulta se aproximam de seu tamanho máximo (Auto) 
-- ==================================================================
*/


ALTER DATABASE [15-implanta]
SET QUERY_STORE = ON (SIZE_BASED_CLEANUP_MODE = AUTO); -- 1 100 MB

-- ==================================================================
--Observação: 5)Stale Query Threshold (Days)
--O número de dias em que o SQL Server mantém dados em Query Store
-- ==================================================================


-- ==================================================================
--Observação: Limpando os dados do query Store
/*Você pode limpar os dados do repositório de consultas clicando em Limpar Dados de Consulta na Consulta.
Armazenar guia da caixa de diálogo Propriedades do banco de dados ou executando uma das instruções
 */
-- ==================================================================


ALTER DATABASE [15-implanta]
SET QUERY_STORE CLEAR ALL;
GO
--Option 2: Use a system stored procedure;
EXEC sys.sp_query_store_flush_db;
GO