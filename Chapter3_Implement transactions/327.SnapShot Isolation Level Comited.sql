/*########################
# OBS: om esta configuração ativada, todas as consultas que normalmente são executadas usando o comando
Chave de nível de isolamento COMMITTED para usar o READ_COMMITTED_SNAPSHOT
nível de isolamento sem exigir que você altere o código da consulta. O SQL Server cria um
instantâneo de dados confirmados quando cada instrução é iniciada. Consequentemente, leia as operações em
pontos diferentes em uma transação podem retornar resultados diferentes.
Durante a transação, o SQL Server copia as linhas modificadas por outras transações em um
coleção de páginas no tempdb conhecido como o armazenamento de versão
*/


 
ALTER DATABASE [15.1-implanta] SET READ_COMMITTED_SNAPSHOT ON WITH ROLLBACK IMMEDIATE;

USE [15.1-implanta];

DELETE FROM Examples.IsolationLevels WHERE RowId >4

BEGIN TRANSACTION;
SELECT RowId,
       ColumnText
FROM Examples.IsolationLevels
WAITFOR DELAY '00:00:10';
SELECT RowId,
       ColumnText
FROM Examples.IsolationLevels;
ROLLBACK TRANSACTION;


/*########################
# OBS: Em outra sessão 
*/
SELECT * FROM Examples.IsolationLevels AS IL

INSERT INTO Examples.IsolationLevels(RowId, ColumnText)
VALUES (7, 'Row 7');


/*########################
# OBS: Exemplo 2
*/


BEGIN TRANSACTION t2;
UPDATE Examples.IsolationLevels SET ColumnText ='Row  update'
WHERE RowId =7

WAITFOR DELAY '00:00:10';

SELECT * FROM Examples.IsolationLevels AS IL

COMMIT TRANSACTION;

/*########################
# OBS:Em outra Sessão
*/

BEGIN TRAN t2
INSERT INTO Examples.IsolationLevels(RowId, ColumnText)
VALUES (9, 'Row 9');

SELECT * FROM Examples.IsolationLevels AS IL

WAITFOR DELAY '00:00:05';
ROLLBACK







ALTER DATABASE ExamBook762Ch3
SET READ_COMMITTED_SNAPSHOT OFF;