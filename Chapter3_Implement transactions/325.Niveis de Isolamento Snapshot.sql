/*########################
# Nenhum bloqueio é adquirido para esse nível de isolamento. Conseqüentemente, deadlocks e bloqueio
as escalações ocorrem com menos frequência, o desempenho é mais rápido e a simultaneidade é maior. Ler
as operações não são bloqueadas por operações de gravação e as operações de gravação não são bloqueadas por
ler operações.
Por outro lado, esses benefícios vêm com um custo indireto. Mais espaço é necessário
tempdb para armazenamento de versão de linha e mais CPU e memória são requeridas pelo SQL Server para
gerenciar o controle de versão de linha. As operações de atualização podem ser executadas mais lentamente como resultado das etapas extras
necessário para gerenciar versões de linha. Além disso, operações de leitura de longa duração podem ser executadas
mais lento se muitas atualizações ou exclusões estiverem ocorrendo e aumentando o comprimento da versão
cadeias que o SQL Server deve verificar. Você pode melhorar o desempenho colocando tempdb em um
unidade de disco dedicada e de alto desempenho.
*/

ALTER DATABASE ExamBook762Ch3 SET ALLOW_SNAPSHOT_ISOLATION ON;

USE ExamBook762Ch3;

SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
BEGIN TRANSACTION;
SELECT RowId,
       ColumnText
FROM Examples.IsolationLevels;
WAITFOR DELAY '00:00:10';
SELECT RowId,
       ColumnText
FROM Examples.IsolationLevels;
ROLLBACK TRANSACTION;


/*########################
# OBS: rode essa query em  sessão
*/

INSERT INTO Examples.IsolationLevels(RowId, ColumnText)
VALUES (7, 'Row 7');