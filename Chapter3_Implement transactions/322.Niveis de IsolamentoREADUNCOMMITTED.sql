
USE ExamBook762Ch3;


/*########################
# OBS: 
Esse nível de isolamento permite leituras sujas, leituras não repetíveis e leituras fantasmas. No
Por outro lado, uma transação definida para esse nível de
 isolamento é executada rapidamente porque bloqueios e
as validações são ignoradas.

READ UNCOMMITTED
Especifica que as instruções podem ler linhas que foram modificadas por outras transações, mas que ainda não foram confirmadas.
Transações em execução em nível READ UNCOMMITTED não emitem bloqueios compartilhados para impedir que outras transações
modifiquem os dados lidos pela transação atual. Transações READ UNCOMMITTED também não são bloqueadas por bloqueios
exclusivos que impediriam a transação atual de ler linhas que foram modificadas, mas não confirmadas, por outras transações.
*/


SELECT * FROM Examples.IsolationLevels AS IL


BEGIN TRANSACTION;
UPDATE Examples.IsolationLevels
SET ColumnText = 'Row 1 Updated'
WHERE RowId = 1;


--Em outra sessão faça  select abaixo

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

--O Contexto do NoLock tambem é a mesma coisa.
SELECT RowId, ColumnText
FROM Examples.IsolationLevels;





ROLLBACK



/*########################
# OBS: Segunda Demo
*/



BEGIN TRANSACTION;
DELETE E FROM
 Examples.IsolationLevels E
WHERE RowId = 1;



/*########################
# OBS: rede essa query em  sessão
*/

SET TRAN ISOLATION LEVEL READ UNCOMMITTED
INSERT INTO Examples.IsolationLevels
VALUES
( 6, 'Row 1' ), 
( 7, 'Row 2' ), 
( 8, 'Row 3' ), 
( 9, 'Row 4' )



SELECT * FROM Examples.IsolationLevels AS IL