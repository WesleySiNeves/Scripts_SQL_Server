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
que é fazer joins com entre banco de dados ativado o Snapshot e outro não
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
É importante saber que o controle de versão de linha se aplica apenas aos dados e não ao sistema
metadados. Se uma instrução alterar metadados de um objeto enquanto uma transação usando o
O nível de isolamento SNAPSHOT está aberto e a transação subseqüentemente faz referência ao
objeto modificado, a transação falha. Esteja ciente de que as operações BULK INSERT podem mudar
os metadados de uma tabela e, como resultado, causam falhas de transação. (Esse comportamento não ocorre
ao usar o nível de isolamento READ_COMMITTED_SNAPSHOT.)
Uma maneira de ver esse comportamento é alterar um índice em uma tabela enquanto uma transação é
aberto. Vamos primeiro adicionar um índice a uma tabela:
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
# OBS: Em outra sessão faremos a alteração de um indice
*/

ALTER INDEX PKRowId ON Examples.IsolationLevels REBUILD;



/*########################
# OBS: Por ultimo desabilite o SnapShot
*/



ALTER DATABASE ExamBook762Ch3
SET ALLOW_SNAPSHOT_ISOLATION OFF;

