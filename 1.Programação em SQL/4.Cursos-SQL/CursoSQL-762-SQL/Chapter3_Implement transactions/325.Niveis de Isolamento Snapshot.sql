/*########################
# Nenhum bloqueio é adquirido para esse nível de isolamento. Conseqüentemente, deadlocks e bloqueio
as escalações ocorrem com menos frequência, o desempenho é mais rápido e a simultaneidade é maior. Ler
as operações não são bloqueadas por operações de gravação e as operações de gravação não são bloqueadas por
ler operações.
Por outro lado, esses benefícios vêm com um custo indireto. Mais espaço é necessário
tempdb para armazenamento de versão de linha e mais CPU e memória são requeridas pelo SQL Server para
gerenciar o controle de versão de linha. As operações de atualização podem ser executadas mais lentamente como resultado das
 etapas extrasnecessário para gerenciar versões de linha. Além disso, operações de leitura de longa duração podem ser executadas
mais lento se muitas atualizações ou exclusões estiverem ocorrendo e aumentando o comprimento da versão
cadeias que o SQL Server deve verificar. Você pode melhorar o desempenho colocando tempdb em um
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
# OBS: rode essa query em  sessão
*/


SELECT * FROM Examples.IsolationLevels AS IL