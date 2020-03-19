-- ==================================================================
--Observa��o: Script para habilitar o query store
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
--Observa��o: Configuracoes
/*
--1)Data Flush Interval (Minutes) 
A frequ�ncia em minutos em que o SQL Server
grava dados coletados pelo armazenamento de consulta em disco.
*/
ALTER DATABASE [15-implanta]
SET QUERY_STORE = ON (DATA_FLUSH_INTERVAL_SECONDS = 3000); --50 minutos;




-- ==================================================================
/* 2)Statistics Collection Interval 
A granularidade do tempo para o qual o SQL Server
agrega estat�sticas de execu��o de tempo de execu��o para o armazenamento de consulta. Voc� pode escolher um dos
seguintes intervalos: 1 minuto, 5 minutos, 10 minutos, 15 minutos, 30 minutos, 1 hora,
ou 1 dia. Se voc� capturar dados com alta frequ�ncia, lembre-se de que o armazenamento de consultas
requer mais espa�o para armazenar dados mais granulados.
 */
-- ==================================================================
ALTER DATABASE [15-implanta]
SET QUERY_STORE = ON (INTERVAL_LENGTH_MINUTES = 1); -- 1 minuto

-- ==================================================================
/* 3)Max Size (MB)
A quantidade m�xima de espa�o alocado para o armazenamento de consulta. o
O valor padr�o � 100 MB por banco de dados. Se o seu banco de dados estiver ativo, esse valor pode n�o
ser grande o suficiente para armazenar planos de consulta e informa��es relacionadas.
 */
-- ==================================================================
ALTER DATABASE [15-implanta]
SET QUERY_STORE = ON (MAX_STORAGE_SIZE_MB = 100); -- 1 100 MB


-- ==================================================================
/* 4) Query Store Capture Mode
A especifica��o dos tipos de consultas para as quais
O SQL Server captura dados para o reposit�rio de consultas. Voc� pode escolher um dos seguintes
op��es:
 */
-- NONE : O armazenamento de consultas para de coletar dados para novas consultas, mas continua
--captura de dados para consultas existentes.

--All : O armazenamento de consulta captura dados para todas as consultas

--Auto : O armazenamento de consulta captura dados para consultas relevantes. Ignora pouco frequente
--consultas e consultas com dura��o de compila��o e execu��o insignificantes
-- ==================================================================

ALTER DATABASE [15-implanta]
SET QUERY_STORE = ON (QUERY_CAPTURE_MODE = AUTO); -- 1 100 MB

-- ==================================================================
--Observa��o:
/* 4) Size Based Cleanup Mode
--A especifica��o de se o processo de limpeza
--ativa quando os dados de armazenamento de consulta se aproximam de seu tamanho m�ximo (Auto) 
-- ==================================================================
*/


ALTER DATABASE [15-implanta]
SET QUERY_STORE = ON (SIZE_BASED_CLEANUP_MODE = AUTO); -- 1 100 MB

-- ==================================================================
--Observa��o: 5)Stale Query Threshold (Days)
--O n�mero de dias em que o SQL Server mant�m dados em Query Store
-- ==================================================================


-- ==================================================================
--Observa��o: Limpando os dados do query Store
/*Voc� pode limpar os dados do reposit�rio de consultas clicando em Limpar Dados de Consulta na Consulta.
Armazenar guia da caixa de di�logo Propriedades do banco de dados ou executando uma das instru��es
 */
-- ==================================================================


ALTER DATABASE [15-implanta]
SET QUERY_STORE CLEAR ALL;
GO
--Option 2: Use a system stored procedure;
EXEC sys.sp_query_store_flush_db;
GO