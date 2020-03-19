/*########################
# OBS: r
O nível de isolamento SERIALIZABLE se comporta como REPEATABLE READ, mas dá um passo
além disso, garantindo que novas linhas adicionadas após o início da transação não sejam visíveis
declaração da transação. Portanto, leituras sujas, leituras não repetitivas e leituras fantasmas
são impedidos.
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
# OBS Em outra sessão rode a query abaixo , veja o comportaamento diferente
do repeatable read
*/

INSERT INTO Examples.IsolationLevels(RowId, ColumnText)
VALUES (5, 'Row 5');


/*########################
# OBS: Agora coloque a transação como serializable
*/
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;


/*########################
# OBS: rede essa query em  sessão
*/
INSERT INTO Examples.IsolationLevels(RowId, ColumnText)
VALUES (6, 'Row 6');