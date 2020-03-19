
USE ExamBook762Ch3;


/*########################
# OBS: 
Esse n�vel de isolamento permite leituras sujas, leituras n�o repet�veis e leituras fantasmas. No
Por outro lado, uma transa��o definida para esse n�vel de
 isolamento � executada rapidamente porque bloqueios e
as valida��es s�o ignoradas.

READ UNCOMMITTED
Especifica que as instru��es podem ler linhas que foram modificadas por outras transa��es, mas que ainda n�o foram confirmadas.
Transa��es em execu��o em n�vel READ UNCOMMITTED n�o emitem bloqueios compartilhados para impedir que outras transa��es
modifiquem os dados lidos pela transa��o atual. Transa��es READ UNCOMMITTED tamb�m n�o s�o bloqueadas por bloqueios
exclusivos que impediriam a transa��o atual de ler linhas que foram modificadas, mas n�o confirmadas, por outras transa��es.
*/


SELECT * FROM Examples.IsolationLevels AS IL


BEGIN TRANSACTION;
UPDATE Examples.IsolationLevels
SET ColumnText = 'Row 1 Updated'
WHERE RowId = 1;


--Em outra sess�o fa�a  select abaixo

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

--O Contexto do NoLock tambem � a mesma coisa.
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
# OBS: rede essa query em  sess�o
*/

SET TRAN ISOLATION LEVEL READ UNCOMMITTED
INSERT INTO Examples.IsolationLevels
VALUES
( 6, 'Row 1' ), 
( 7, 'Row 2' ), 
( 8, 'Row 3' ), 
( 9, 'Row 4' )



SELECT * FROM Examples.IsolationLevels AS IL