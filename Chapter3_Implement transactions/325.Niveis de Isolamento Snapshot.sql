/*########################
# Nenhum bloqueio � adquirido para esse n�vel de isolamento. Conseq�entemente, deadlocks e bloqueio
as escala��es ocorrem com menos frequ�ncia, o desempenho � mais r�pido e a simultaneidade � maior. Ler
as opera��es n�o s�o bloqueadas por opera��es de grava��o e as opera��es de grava��o n�o s�o bloqueadas por
ler opera��es.
Por outro lado, esses benef�cios v�m com um custo indireto. Mais espa�o � necess�rio
tempdb para armazenamento de vers�o de linha e mais CPU e mem�ria s�o requeridas pelo SQL Server para
gerenciar o controle de vers�o de linha. As opera��es de atualiza��o podem ser executadas mais lentamente como resultado das
 etapas extrasnecess�rio para gerenciar vers�es de linha. Al�m disso, opera��es de leitura de longa dura��o podem ser executadas
mais lento se muitas atualiza��es ou exclus�es estiverem ocorrendo e aumentando o comprimento da vers�o
cadeias que o SQL Server deve verificar. Voc� pode melhorar o desempenho colocando tempdb em um
unidade de disco dedicada e de alto desempenho.
*/



ALTER DATABASE [15.1-implanta] SET ALLOW_SNAPSHOT_ISOLATION ON


--INSERT INTO Examples.IsolationLevels(RowId, ColumnText)
--VALUES (7, 'Row 7');

DELETE FROM Examples.IsolationLevels
WHERE RowId >= 7

SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
--SET TRANSACTION ISOLATION  LEVEL READ COMMITTED
--BEGIN TRANSACTION t1;
SELECT RowId,
       ColumnText
FROM Examples.IsolationLevels;
WAITFOR DELAY '00:00:15';
SELECT RowId,
       ColumnText
FROM Examples.IsolationLevels;
--ROLLBACK TRANSACTION;
--COMMIT TRANSACTION t1;





SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

BEGIN TRANSACTION t2;

UPDATE Examples.IsolationLevels
SET ColumnText ='Update Row'
WHERE RowId =1
WAITFOR DELAY '00:00:15';

ROLLBACK


/*########################
# OBS: rode essa query em  sess�o
*/


SELECT * FROM Examples.IsolationLevels AS IL