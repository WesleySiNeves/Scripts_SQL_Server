/*########################
# OBS: 
REPEATABLE READ
Especifica que as instruções não podem ler dados 
que foram modificados, mas que ainda não foram
 confirmados por outras transações e que nenhuma
  outra transação pode modificar dados que 
foram lidos pela transação atual até que a
transação atual seja concluída.

Os bloqueios compartilhados são colocados em todos os dados lidos
por cada instrução na transação,sendo mantidos até que a transação 
seja concluída. Isso impede que outras transações modifiquem qualquer 
linha que tenha sido lida pela transação atual. 
Outras transações podem inserir novas linhas que correspondam às 
condições de pesquisa das instruções emitidas pela transação atual.
 Então, se a transação atual tentar a
instrução novamente, ela recuperará as novas linhas,
 o que resultará em leituras fantasmas. 
Como os bloqueios compartilhados são mantidos até o 
término da transação, em vez de serem liberados
ao final de cada instrução, a simultaneidade é 
menor que o nível de isolamento READ COMMITTED padrão. 
Use essa opção apenas quando necessário.

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
# OBS:em uma segunda sessão rode o script abaixo
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