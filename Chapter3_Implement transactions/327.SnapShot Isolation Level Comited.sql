/*########################
# OBS: om esta configura��o ativada, todas as consultas que normalmente s�o executadas usando o comando
Chave de n�vel de isolamento COMMITTED para usar o READ_COMMITTED_SNAPSHOT
n�vel de isolamento sem exigir que voc� altere o c�digo da consulta. O SQL Server cria um
instant�neo de dados confirmados quando cada instru��o � iniciada. Consequentemente, leia as opera��es em
pontos diferentes em uma transa��o podem retornar resultados diferentes.
Durante a transa��o, o SQL Server copia as linhas modificadas por outras transa��es em um
cole��o de p�ginas no tempdb conhecido como o armazenamento de vers�o
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
# OBS: Em outra sess�o 
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
# OBS:Em outra Sess�o
*/

BEGIN TRAN t2
INSERT INTO Examples.IsolationLevels(RowId, ColumnText)
VALUES (9, 'Row 9');

SELECT * FROM Examples.IsolationLevels AS IL

WAITFOR DELAY '00:00:05';
ROLLBACK







ALTER DATABASE ExamBook762Ch3
SET READ_COMMITTED_SNAPSHOT OFF;