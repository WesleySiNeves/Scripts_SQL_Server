USE ExamBook762Ch3;

/*########################
# OBS: dropa a tabela se existir
*/
DROP TABLE IF EXISTS Examples.IsolationLevels 


/*########################
# OBS: cria a tabela e insere uma massa de dados
*/
CREATE TABLE Examples.IsolationLevels
(
    RowId INT NOT NULL
        CONSTRAINT PKRowId PRIMARY KEY,
    ColumnText VARCHAR(100) NOT NULL
);
INSERT INTO Examples.IsolationLevels
(
    RowId,
    ColumnText
)
VALUES
(1, 'Row 1'),
(2, 'Row 2'),
(3, 'Row 3'),
(4, 'Row 4');



---Nivel de isolamento	 READ COMMITTED

/*########################
# OBS: 
READ COMMITTED
Especifica que as instru��es n�o podem ler dados que foram modificados, mas que ainda n�o foram confirmados
 por outras transa��es. Isso impede leituras sujas. Os dados podem ser alterados por outras transa��es
  entre instru��es individuais dentro da transa��o atual, resultando em 
leituras n�o repet�veis ou dados fantasmas. Essa � a op��o padr�o do SQL Server.
*/
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

BEGIN TRANSACTION;
UPDATE Examples.IsolationLevels
SET ColumnText = 'Row 1 Updated'
WHERE RowId = 1;



--Em nova sess�o 
--Em nova sess�o 
SELECT RowId, ColumnText
FROM Examples.IsolationLevels;


--Em nova sess�o 
--Em nova sess�o 
SELECT RowId, ColumnText
FROM Examples.IsolationLevels
WHERE ColumnText IN
(
'Row 2',
'Row 3',
'Row 4'
)




INSERT INTO Examples.IsolationLevels
(
    RowId,
    ColumnText
)
VALUES
(   5, -- RowId - int
    'Row 5' -- ColumnText - varchar(100)
)


--CREATE  NONCLUSTERED INDEX IdxName ON Examples.IsolationLevels(ColumnText)

--DROP INDEX IdxName ON Examples.IsolationLevels

--ROLLBACK