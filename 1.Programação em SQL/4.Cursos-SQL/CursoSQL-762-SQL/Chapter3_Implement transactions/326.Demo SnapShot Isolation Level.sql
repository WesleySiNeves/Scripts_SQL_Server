/*########################
# Cria o banco de dados
*/

CREATE DATABASE ExamBook762Ch3_IsolationTest;
GO
USE ExamBook762Ch3_IsolationTest;
GO
CREATE SCHEMA Examples;
GO
CREATE TABLE Examples.IsolationLevelsTest
(
    RowId INT NOT NULL
        CONSTRAINT PKRowId PRIMARY KEY,
    ColumnText VARCHAR(100) NOT NULL
);
INSERT INTO Examples.IsolationLevelsTest
(
    RowId,
    ColumnText
)
VALUES
(1, 'Row 1'),
(2, 'Row 2'),
(3, 'Row 3'),
(4, 'Row 4');


SELECT *
FROM Examples.IsolationLevelsTest AS ILT;



/*########################
# OBS:  Aqui apenas criamos um banco , vamos fazer um primeiro teste
que � fazer joins com entre banco de dados ativado o Snapshot e outro n�o
*/

/*########################
# OBS:Veja que o banco  ExamBook762Ch3 esta hablitado
*/
USE ExamBook762Ch3;



SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
BEGIN TRANSACTION;
SELECT t1.RowId,
       t2.ColumnText
FROM Examples.IsolationLevels AS t1
    INNER JOIN ExamBook762Ch3_IsolationTest.Examples.IsolationLevelsTest AS t2
        ON t1.RowId = t2.RowId;




/*########################
# OBS: para resulver isso vc precisa usar a dica de tabela
*/




SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
BEGIN TRANSACTION;
SELECT t1.RowId,
       t2.ColumnText
FROM Examples.IsolationLevels AS t1
    INNER JOIN ExamBook762Ch3_IsolationTest.Examples.IsolationLevelsTest t2 WITH(READCOMMITTED)
        ON t1.RowId = t2.RowId;


/*########################
# OBS: Outra coisa a saber 
� importante saber que o controle de vers�o de linha se aplica apenas aos dados e n�o ao sistema
metadados. Se uma instru��o alterar metadados de um objeto enquanto uma transa��o usando o
O n�vel de isolamento SNAPSHOT est� aberto e a transa��o subseq�entemente faz refer�ncia ao
objeto modificado, a transa��o falha. Esteja ciente de que as opera��es BULK INSERT podem mudar
os metadados de uma tabela e, como resultado, causam falhas de transa��o. (Esse comportamento n�o ocorre
ao usar o n�vel de isolamento READ_COMMITTED_SNAPSHOT.)
Uma maneira de ver esse comportamento � alterar um �ndice em uma tabela enquanto uma transa��o �
aberto. Vamos primeiro adicionar um �ndice a uma tabela:
*/


/*########################
# OBS: Exemplo
*/

SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
BEGIN TRANSACTION;
SELECT RowId, ColumnText
FROM Examples.IsolationLevels;
WAITFOR DELAY '00:00:10';
SELECT RowId, ColumnText
FROM Examples.IsolationLevels;
ROLLBACK TRANSACTION;


/*########################
# OBS: Em outra sess�o faremos a altera��o de um indice
*/

ALTER INDEX PKRowId ON Examples.IsolationLevels REBUILD;



/*########################
# OBS: Por ultimo desabilite o SnapShot
*/



ALTER DATABASE ExamBook762Ch3
SET ALLOW_SNAPSHOT_ISOLATION OFF;

