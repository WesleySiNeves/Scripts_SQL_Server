USE DemoDB

/* ==================================================================
--Data: 25/09/2018 
--Autor :Wesley Neves
--Observa��o: Nessa configur���o o banco n�o fica acessivel a ninguem
 
-- ==================================================================
*/
ALTER DATABASE DemoDB SET OFFLINE

/* ==================================================================
--Data: 25/09/2018 
--Autor :Wesley Neves
--Observa��o: Nessa op��o o banco � acessivel aos sysAdmins
 
-- ==================================================================
*/
ALTER DATABASE DemoDB SET EMERGENCY

ALTER DATABASE DemoDB SET ONLINE 


/* ==================================================================
--Data: 25/09/2018 
--Autor :Wesley Neves
--Observa��o:  nessa configura��o n�o se pode fazer altera��es no banco
 
-- ==================================================================
*/
ALTER DATABASE DemoDB SET READ_ONLY 
