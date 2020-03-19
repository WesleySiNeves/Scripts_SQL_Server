/*########################
# OBS: r
O n�vel de isolamento SERIALIZABLE se comporta como REPEATABLE READ, mas d� um passo
al�m disso, garantindo que novas linhas adicionadas ap�s o in�cio da transa��o n�o sejam vis�veis
declara��o da transa��o. Portanto, leituras sujas, leituras n�o repetitivas e leituras fantasmas
s�o impedidos.
*/

USE ExamBook762Ch3;




--SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION;
SELECT RowId, ColumnText
FROM Examples.IsolationLevels;

WAITFOR DELAY '00:00:10';

SELECT RowId, ColumnText
FROM Examples.IsolationLevels;
ROLLBACK TRANSACTION;


/*########################
# OBS Em outra sess�o rode a query abaixo , veja o comportaamento diferente
do repeatable read
*/

INSERT INTO Examples.IsolationLevels(RowId, ColumnText)
VALUES (5, 'Row 5');


/*########################
# OBS: Agora coloque a transa��o como serializable
*/
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;


/*########################
# OBS: rede essa query em  sess�o
*/
INSERT INTO Examples.IsolationLevels(RowId, ColumnText)
VALUES (6, 'Row 6');