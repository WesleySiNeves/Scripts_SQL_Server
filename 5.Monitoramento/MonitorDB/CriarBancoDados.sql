
IF(NOT EXISTS(
SELECT * FROM  sys.databases AS D
WHERE D.name ='Monitor'))
BEGIN
CREATE DATABASE Monitor		
END

GO



USE Monitor

GO





CREATE OR ALTER FUNCTION  Monitor.ufnBuscaCollate(@Database NVARCHAR(200),@ValidarCollateDiferenteDoBanco BIT = 0)
RETURNS TABLE  AS
 RETURN  


WITH Dados AS (

--Verifica o Collation de todos os campos do banco de dados
SELECT   S.name AS SCHEMAName,
		 t2.name  AS Tabela ,
		c.name CollummName,
       t.name AS TypeName,
	   c.max_length,
       c.is_nullable,
       c.is_rowguidcol,
       c.is_identity,
       c.is_computed,
       c.collation_name
	 
  FROM sys.columns AS c
  JOIN sys.tables AS T2 ON t2.object_id = C.object_id
  JOIN sys.schemas AS S ON T2.schema_id = S.schema_id
  JOIN sys.types AS t
    ON t.user_type_id = c.user_type_id
 WHERE c.object_id IN ( SELECT objects.object_id FROM sys.objects WHERE objects.type = 'U' ) --Coluna
   AND (   (   @ValidarCollateDiferenteDoBanco = 1
         AND   c.collation_name                <> DATABASEPROPERTYEX(@Database, 'Collation'))
      OR   @ValidarCollateDiferenteDoBanco     = 0)
)
SELECT R.SCHEMAName,
       R.Tabela,
       R.CollummName,
       R.TypeName,
       R.max_length,
       R.is_nullable,
       R.is_rowguidcol,
       R.is_identity,
       R.is_computed,
       R.collation_name,
	     [Script] = CONCAT('ALTER TABLE ', QUOTENAME(R.SCHEMAName),'.', QUOTENAME(R.Tabela),' ALTER COLUMN ',
		 QUOTENAME( R.CollummName),' ',
		 R.TypeName,'(', IIF( R.max_length = -1,'MAX', CAST(R.max_length AS VARCHAR(5))),') COLLATE  DATABASE_DEFAULT') -- ALTER TABLE Financeiro.MotivosCancelamentos ALTER COLUMN Nome VARCHAR(250) COLLATE  DATABASE_DEFAULT 
		 FROM  Dados R
		 
 --ORDER BY R.SCHEMAName DESC;




 
 CREATE OR ALTER FUNCTION Transacao.MonitoraTransacoesAtivas(@DataBaseName VARCHAR(150))
 RETURNS TABLE  AS
 RETURN 
 

WITH ResultSet AS (
SELECT [Database] = COALESCE(DB_NAME(DTDT.database_id),DB_NAME()),
       [Usuario] = DES.login_name,
       [Maquina Conectada] = DES.host_name,
       [Sessão] = DES.session_id,
       [transaction_id] = DTDT.transaction_id,
       [Nivel Isolamento] =  CASE WHEN DES.transaction_isolation_level =0 THEN 'Não Especificado'
								  WHEN DES.transaction_isolation_level =1 THEN 'Leitura Não Confirmada'
								  WHEN DES.transaction_isolation_level =2 THEN 'Leitura Confirmada'
								  WHEN DES.transaction_isolation_level =3 THEN 'Repetível'
								  WHEN DES.transaction_isolation_level =4 THEN 'Serializável'
								  WHEN DES.transaction_isolation_level =5 THEN 'Instantâneo' END,
	   
	   [Tempo da transação aberta] =CONVERT(TIME,DATEADD (ms, DATEDIFF(MILLISECOND, DTDT.database_transaction_begin_time, CURRENT_TIMESTAMP), 0)),
	   [lock_timeout config session] = DES.lock_timeout,
	     [time  last query]  =CONVERT(TIME,DATEADD (ms, DATEDIFF(MILLISECOND, DES.last_request_start_time, DES.last_request_end_time), 0)),
	   s_est.text AS [Last T-SQL Text],
	   [Tamanho Pacote] = DEC.net_packet_size,
       [Transaction_type] = CASE
                                WHEN DTDT.database_transaction_type = 1 THEN
                                    'Transação de leitura/gravação'
                                WHEN DTDT.database_transaction_type = 2 THEN
                                    'Transação somente leitura'
                                WHEN DTDT.database_transaction_type = 3 THEN
                                    'Transação de sistema'
                            END,
       [Transaction_state] = CASE
                                 WHEN DTDT.database_transaction_state = 1 THEN
                                     'A transação não foi inicializada'
                                 WHEN DTDT.database_transaction_state = 3 THEN
                                     'A transação foi inicializada mas não gerou registros de log'
                                 WHEN DTDT.database_transaction_state = 4 THEN
                                     'A transação gerou registros de log.'
                                 WHEN DTDT.database_transaction_state = 5 THEN
                                     'A transação foi preparada'
                                 WHEN DTDT.database_transaction_state = 10 THEN
                                     'A transação efetuou COMMIT'
                                 WHEN DTDT.database_transaction_state = 11 THEN
                                     'A transação efetuou ROLLBACK'
                                 WHEN DTDT.database_transaction_state = 12 THEN
                                     'A transação está sendo confirmada. (O registro de log está sendo gerado, mas não foi materializado ou persistente.)'
                             END,
       [bytes_used] = DTDT.database_transaction_log_bytes_used,
       [bytes_reserved] = DTDT.database_transaction_log_bytes_reserved,
       [Quantidade de Transacoes] = s_tst.open_transaction_count,
	 
       s_eqp.query_plan AS [Last Plan]
      -- [begin_lsn] = DTDT.database_transaction_begin_lsn,
      -- [last_lsn] = DTDT.database_transaction_last_lsn
FROM sys.dm_tran_database_transactions AS DTDT
    LEFT JOIN sys.dm_tran_session_transactions [s_tst] ON s_tst.transaction_id = DTDT.transaction_id
    LEFT JOIN sys.dm_exec_sessions AS DES ON DES.session_id = s_tst.session_id
	LEFT JOIN sys.dm_exec_connections AS DEC ON DES.session_id = DEC.session_id
	LEFT OUTER JOIN sys.dm_exec_requests [s_er] ON s_er.session_id = s_tst.session_id
    CROSS APPLY sys.dm_exec_sql_text(DEC.most_recent_sql_handle) AS [s_est]
    OUTER APPLY sys.dm_exec_query_plan(s_er.plan_handle) AS [s_eqp]
--WHERE DTDT.database_id = DB_ID()
)
SELECT R.[Database],
       R.Usuario,
       R.[Maquina Conectada],
       R.Sessão,
       R.transaction_id,
       R.[Nivel Isolamento],
       R.[Tempo da transação aberta],
       R.[lock_timeout config session],
       R.[time  last query],
       R.[Last T-SQL Text],
       R.[Tamanho Pacote],
       R.Transaction_type,
       R.Transaction_state,
       R.bytes_used,
       R.bytes_reserved,
       R.[Quantidade de Transacoes],
       R.[Last Plan]
	    FROM ResultSet R
WHERE R.[Database] <>'tempdb'
ORDER BY R.[Tempo da transação aberta]
OFFSET 0 ROW FETCH NEXT 100000 ROW ONLY



GO



 CREATE OR ALTER FUNCTION Transacao.MonitoraTamanhoTabelas(@DataBaseName VARCHAR(150))
 RETURNS TABLE  AS
 RETURN 
/*
https://docs.microsoft.com/pt-br/sql/relational-databases/system-catalog-views/sys-allocation-units-transact-sql?view=sql-server-2017
*/
WITH Dados AS (
SELECT 
    t.name AS TableName,
    s.name AS SchemaName,
    p.rows AS RowCounts,
    SUM(a.total_pages) * 8 AS TotalSpaceKB, 
	SUM(a.used_pages) * 8 AS UsedSpaceKB, 
	(SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB,
    CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS TotalReservadoMB,
    CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS TotalUsadoMB, 
    CAST(ROUND(((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS EspacoNaoUsadoMB
FROM 
    sys.tables t
INNER JOIN      
    sys.indexes i ON t.object_id = i.object_id
INNER JOIN 
    sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN 
    sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
WHERE 
    t.name NOT LIKE 'dt%' 
    AND t.is_ms_shipped = 0
    AND i.object_id > 255 
GROUP BY 
    t.name, s.name, p.rows

)
SELECT R.TableName,
       R.SchemaName,
       RowCounts = FORMAT(R.RowCounts,'N','pt-BR'),
       R.TotalSpaceKB,
       R.UsedSpaceKB,
       R.UnusedSpaceKB,
       R.TotalReservadoMB,
       R.TotalUsadoMB,
       R.EspacoNaoUsadoMB FROM Dados R
ORDER BY R.TotalReservadoMB DESC
OFFSET 0 ROWS FETCH NEXT 100000 ROWS ONLY




GO

CREATE OR ALTER FUNCTION Monitor.ufnBuscaFksDeUmaColuna (@CollumName VARCHAR(150))
RETURNS TABLE
AS
RETURN (
       SELECT C.CONSTRAINT_NAME [constraint_name],
              C.TABLE_NAME [referencing_table_name],
              KCU.COLUMN_NAME [referencing_column_name],
              C2.TABLE_NAME [referenced_table_name],
              KCU2.COLUMN_NAME [referenced_column_name],
              RC.DELETE_RULE delete_referential_action_desc,
              RC.UPDATE_RULE update_referential_action_desc
       FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS C
            INNER JOIN
            INFORMATION_SCHEMA.KEY_COLUMN_USAGE KCU ON C.CONSTRAINT_SCHEMA = KCU.CONSTRAINT_SCHEMA
                                                       AND C.CONSTRAINT_NAME = KCU.CONSTRAINT_NAME
            INNER JOIN
            INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS RC ON C.CONSTRAINT_SCHEMA = RC.CONSTRAINT_SCHEMA
                                                             AND C.CONSTRAINT_NAME = RC.CONSTRAINT_NAME
            INNER JOIN
            INFORMATION_SCHEMA.TABLE_CONSTRAINTS C2 ON RC.UNIQUE_CONSTRAINT_SCHEMA = C2.CONSTRAINT_SCHEMA
                                                       AND RC.UNIQUE_CONSTRAINT_NAME = C2.CONSTRAINT_NAME
            INNER JOIN
            INFORMATION_SCHEMA.KEY_COLUMN_USAGE KCU2 ON C2.CONSTRAINT_SCHEMA = KCU2.CONSTRAINT_SCHEMA
                                                        AND C2.CONSTRAINT_NAME = KCU2.CONSTRAINT_NAME
                                                        AND KCU.ORDINAL_POSITION = KCU2.ORDINAL_POSITION
       WHERE C.CONSTRAINT_TYPE = 'FOREIGN KEY'
             AND KCU2.COLUMN_NAME = @CollumName
       ORDER BY
           C.CONSTRAINT_NAME OFFSET 0 ROWS FETCH NEXT 100000 ROWS ONLY
       );

 

 GO
 
 
CREATE PROCEDURE Helper.DeletaGeraScriptDelecaoForenkey(@Coluna VARCHAR(200))

AS 
BEGIN	

;WITH    DadosContrutor
          AS ( SELECT   C.CONSTRAINT_NAME [constraint_name] ,
                        C.CONSTRAINT_SCHEMA [FK SCHEMA] ,
                        C.TABLE_NAME [Tabela Filha] ,
                        KCU.COLUMN_NAME [ColunaFilha] ,
                        C2.CONSTRAINT_SCHEMA [Schema Pai] ,
                        C2.TABLE_NAME [Tabela Pai] ,
                        KCU2.COLUMN_NAME [Coluna Pai] ,
                        RC.DELETE_RULE delete_referential_action_desc ,
                        RC.UPDATE_RULE update_referential_action_desc
               FROM     INFORMATION_SCHEMA.TABLE_CONSTRAINTS C
                        INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE KCU ON C.CONSTRAINT_SCHEMA = KCU.CONSTRAINT_SCHEMA
                                                              AND C.CONSTRAINT_NAME = KCU.CONSTRAINT_NAME
                        INNER JOIN INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS RC ON C.CONSTRAINT_SCHEMA = RC.CONSTRAINT_SCHEMA
                                                              AND C.CONSTRAINT_NAME = RC.CONSTRAINT_NAME
                        INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS C2 ON RC.UNIQUE_CONSTRAINT_SCHEMA = C2.CONSTRAINT_SCHEMA
                                                              AND RC.UNIQUE_CONSTRAINT_NAME = C2.CONSTRAINT_NAME
                        INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE KCU2 ON C2.CONSTRAINT_SCHEMA = KCU2.CONSTRAINT_SCHEMA
                                                              AND C2.CONSTRAINT_NAME = KCU2.CONSTRAINT_NAME
                                                              AND KCU.ORDINAL_POSITION = KCU2.ORDINAL_POSITION
               WHERE    C.CONSTRAINT_TYPE = 'FOREIGN KEY'
                        AND KCU2.COLUMN_NAME = 'IdPlanoConta'
             )
    SELECT  PC.constraint_name ,
            PC.[FK SCHEMA] ,
            PC.[Tabela Filha] ,
            PC.[ColunaFilha] ,
            PC.[Schema Pai] ,
            PC.[Tabela Pai] ,
            PC.[Coluna Pai] ,
            PC.delete_referential_action_desc ,
            PC.update_referential_action_desc ,
            [Passo1 SqlDropFK] = CONCAT('IF(EXISTS(SELECT 1 FROM ', '[',
                                        PC.[FK SCHEMA], '].', '[',
                                        PC.[Tabela Filha], '])) BEGIN ')
            + CONCAT('ALTER TABLE', SPACE(2), '[', PC.[FK SCHEMA], ']', '.',
                     '[', PC.[Tabela Filha], ']', SPACE(2), 'DROP CONSTRAINT',
                     SPACE(2), '[', PC.constraint_name, ']; END') ,
            [SqlCreateFKUpdateCascate] = CONCAT('IF(EXISTS(SELECT 1 FROM ',
                                                '[', PC.[FK SCHEMA], '].', '[',
                                                PC.[Tabela Filha],
                                                '])) BEGIN ')
            + CONCAT('ALTER TABLE', SPACE(2), '[', PC.[FK SCHEMA], ']', '.',
                     '[', PC.[Tabela Filha], ']', SPACE(2),
                     'WITH CHECK ADD CONSTRAINT', SPACE(2), '[',
                     PC.constraint_name, ']', SPACE(2), 'FOREIGN KEY([',
                     PC.ColunaFilha, '])', SPACE(2), 'REFERENCES', SPACE(2),
                     PC.[Schema Pai], '.', PC.[Tabela Pai], '([',
                     PC.[Coluna Pai], ']) ON UPDATE  CASCADE ', ' ON DELETE ',
                     PC.delete_referential_action_desc, ' ; END') ,
            [SqlCreateFKDoJeitoQueEra] = CONCAT('IF(EXISTS(SELECT 1 FROM ',
                                                '[', PC.[FK SCHEMA], '].', '[',
                                                PC.[Tabela Filha],
                                                '])) BEGIN ')
            + CONCAT('ALTER TABLE', SPACE(2), '[', PC.[FK SCHEMA], ']', '.',
                     '[', PC.[Tabela Filha], ']', SPACE(2),
                     'WITH CHECK ADD CONSTRAINT', SPACE(2), '[',
                     PC.constraint_name, ']', SPACE(2), 'FOREIGN KEY([',
                     PC.ColunaFilha, '])', SPACE(2), 'REFERENCES', SPACE(2),
                     PC.[Schema Pai], '.', PC.[Tabela Pai], '([',
                     PC.[Coluna Pai], ']) ON UPDATE ',
                     PC.update_referential_action_desc, ' ON DELETE ',
                     PC.delete_referential_action_desc, '; END')
    FROM    DadosContrutor PC;

END





GO


CREATE PROCEDURE Helper.uspGeraScriptDesabilitarEHabilitarForenkey(@Coluna VARCHAR(200))

AS 
BEGIN	


WITH    DadosContrutor
          AS ( SELECT   C.CONSTRAINT_NAME [constraint_name] ,
                        C.CONSTRAINT_SCHEMA [FK SCHEMA] ,
                        C.TABLE_NAME [Tabela Filha] ,
                        KCU.COLUMN_NAME [ColunaFilha] ,
                        C2.CONSTRAINT_SCHEMA [Schema Pai] ,
                        C2.TABLE_NAME [Tabela Pai] ,
                        KCU2.COLUMN_NAME [Coluna Pai] ,
                        RC.DELETE_RULE delete_referential_action_desc ,
                        RC.UPDATE_RULE update_referential_action_desc
               FROM     INFORMATION_SCHEMA.TABLE_CONSTRAINTS C
                        INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE KCU ON C.CONSTRAINT_SCHEMA = KCU.CONSTRAINT_SCHEMA
                                                              AND C.CONSTRAINT_NAME = KCU.CONSTRAINT_NAME
                        INNER JOIN INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS RC ON C.CONSTRAINT_SCHEMA = RC.CONSTRAINT_SCHEMA
                                                              AND C.CONSTRAINT_NAME = RC.CONSTRAINT_NAME
                        INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS C2 ON RC.UNIQUE_CONSTRAINT_SCHEMA = C2.CONSTRAINT_SCHEMA
                                                              AND RC.UNIQUE_CONSTRAINT_NAME = C2.CONSTRAINT_NAME
                        INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE KCU2 ON C2.CONSTRAINT_SCHEMA = KCU2.CONSTRAINT_SCHEMA
                                                              AND C2.CONSTRAINT_NAME = KCU2.CONSTRAINT_NAME
                                                              AND KCU.ORDINAL_POSITION = KCU2.ORDINAL_POSITION
               WHERE    C.CONSTRAINT_TYPE = 'FOREIGN KEY'
                        AND KCU2.COLUMN_NAME = @Coluna
             )
    SELECT  PC.constraint_name ,
            PC.[FK SCHEMA] ,
            PC.[Tabela Filha] ,
            PC.[ColunaFilha] ,
            PC.[Schema Pai] ,
            PC.[Tabela Pai] ,
            PC.[Coluna Pai] ,
            PC.delete_referential_action_desc ,
            PC.update_referential_action_desc ,
            [Passo1 Sql Disable FK] = CONCAT('IF(EXISTS(SELECT 1 FROM ', '[',
                                        PC.[FK SCHEMA], '].', '[',
                                        PC.[Tabela Filha], '])) BEGIN ')
            + CONCAT('ALTER TABLE', SPACE(2), '[', PC.[FK SCHEMA], ']', '.',
                     '[', PC.[Tabela Filha], ']', SPACE(2), 'NOCHECK CONSTRAINT',
                     SPACE(2), '[', PC.constraint_name, ']; END') ,
            [Passo2 Sql Enable FK] = CONCAT('IF(EXISTS(SELECT 1 FROM ', '[',
                                        PC.[FK SCHEMA], '].', '[',
                                        PC.[Tabela Filha], '])) BEGIN ')
            + CONCAT('ALTER TABLE', SPACE(2), '[', PC.[FK SCHEMA], ']', '.',
                     '[', PC.[Tabela Filha], ']', SPACE(2), 'WITH CHECK CHECK CONSTRAINT',
                     SPACE(2), '[', PC.constraint_name, ']; END')
    FROM    DadosContrutor PC;

	END
