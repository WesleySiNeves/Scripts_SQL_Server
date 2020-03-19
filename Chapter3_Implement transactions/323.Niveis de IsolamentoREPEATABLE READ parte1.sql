/*########################
# OBS: 
REPEATABLE READ
Especifica que as instru��es n�o podem ler dados 
que foram modificados, mas que ainda n�o foram
 confirmados por outras transa��es e que nenhuma
  outra transa��o pode modificar dados que 
foram lidos pela transa��o atual at� que a
transa��o atual seja conclu�da.

Os bloqueios compartilhados s�o colocados em todos os dados lidos
por cada instru��o na transa��o,sendo mantidos at� que a transa��o 
seja conclu�da. Isso impede que outras transa��es modifiquem qualquer 
linha que tenha sido lida pela transa��o atual. 
Outras transa��es podem inserir novas linhas que correspondam �s 
condi��es de pesquisa das instru��es emitidas pela transa��o atual.
 Ent�o, se a transa��o atual tentar a
instru��o novamente, ela recuperar� as novas linhas,
 o que resultar� em leituras fantasmas. 
Como os bloqueios compartilhados s�o mantidos at� o 
t�rmino da transa��o, em vez de serem liberados
ao final de cada instru��o, a simultaneidade � 
menor que o n�vel de isolamento READ COMMITTED padr�o. 
Use essa op��o apenas quando necess�rio.

*/

USE ExamBook762Ch3;

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
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
# OBS:em uma segunda sess�o rode o script abaixo
*/
UPDATE Examples.IsolationLevels
SET ColumnText = 'Row 1 Updated'
WHERE RowId = 1;



/*########################
# OBS: segunda demo e com insert
*/

INSERT INTO Examples.IsolationLevels
(
    RowId,
    ColumnText
)
VALUES
(   5, -- RowId - int
    'row 5' -- ColumnText - varchar(100)
)


--DELETE FROM Examples.IsolationLevels WHERE 
--RowId >4