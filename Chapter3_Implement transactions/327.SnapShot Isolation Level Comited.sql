/*########################
# OBS: om esta configura��o ativada, todas as consultas que normalmente s�o executadas usando o comando
Chave de n�vel de isolamento COMMITTED para usar o READ_COMMITTED_SNAPSHOT
n�vel de isolamento sem exigir que voc� altere o c�digo da consulta. O SQL Server cria um
instant�neo de dados confirmados quando cada instru��o � iniciada. Consequentemente, leia as opera��es em
pontos diferentes em uma transa��o podem retornar resultados diferentes.
Durante a transa��o, o SQL Server copia as linhas modificadas por outras transa��es em um
cole��o de p�ginas no tempdb conhecido como o armazenamento de vers�o
*/

ALTER DATABASE ExamBook762Ch3 SET READ_COMMITTED_SNAPSHOT ON;

USE ExamBook762Ch3;

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


INSERT INTO Examples.IsolationLevels(RowId, ColumnText)
VALUES (8, 'Row 8');


/*########################
# OBS: Exemplo 2
*/
UPDATE Examples.IsolationLevels SET ColumnText ='Row update'
WHERE RowId =7


/*########################
# OBS: Exemplo 3
*/

BEGIN TRAN t2
INSERT INTO Examples.IsolationLevels(RowId, ColumnText)
VALUES (8, 'Row 8');





ALTER DATABASE ExamBook762Ch3
SET READ_COMMITTED_SNAPSHOT OFF;