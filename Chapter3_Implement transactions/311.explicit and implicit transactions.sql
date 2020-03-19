use [ExamBook762Ch3]

/*Implicit transactions
 vc tem que configurar a opção
 SET IMPLICIT_TRANSACTIONS ON;
 */


 /*Modo padrão */
 select * from [Examples].[TestParent]

SELECT @@TRANCOUNT;

 INSERT INTO Examples.TestParent(ParentId, ParentName)
VALUES (6, 'Lukas');

SELECT @@TRANCOUNT;



/*Alterando a configuracao*/
 SET IMPLICIT_TRANSACTIONS ON;


  select * from [Examples].[TestParent]

SELECT @@TRANCOUNT;

 INSERT INTO Examples.TestParent(ParentId, ParentName)
VALUES (7, 'Karina');

SELECT @@TRANCOUNT;


SET IMPLICIT_TRANSACTIONS OFF;


/*transações explicitas*/

--exemplo

BEGIN TRANSACTION;
INSERT INTO Examples.TestParent(ParentId, ParentName)
VALUES (7, 'Mary');
DELETE Examples.TestParent
WHERE ParentName = 'Bob';
IF @@ERROR != 0
BEGIN
ROLLBACK TRANSACTION;
RETURN
END
COMMIT TRANSACTION;




/*transações explicitas segundo exemplo*/

--exemplo

BEGIN TRANSACTION T1;

delete from  [Examples].[TestParent] where ParentId =6

select * from [Examples].[TestParent]


	BEGIN TRANSACTION T2;
	delete from  [Examples].[TestParent] where ParentId =5

	select * from [Examples].[TestParent]

	COMMIT TRANSACTION T2;

	/*Somente quando @@TRANCOUNT estiver igual a zero que o Sql servr
	escreve no transaction log
	se vc fizer um ROLLBACK TRANSACTION t1 a transação t2 e disfeita*/
	select @@TRANCOUNT;


IF @@ERROR != 0
BEGIN
ROLLBACK TRANSACTION T1;
RETURN
END
COMMIT TRANSACTION;



