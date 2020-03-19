USE DemoDB

/* ==================================================================
--Data: 25/09/2018 
--Autor :Wesley Neves
--Observação: Nessa configurãção o banco não fica acessivel a ninguem
 
-- ==================================================================
*/
ALTER DATABASE DemoDB SET OFFLINE

/* ==================================================================
--Data: 25/09/2018 
--Autor :Wesley Neves
--Observação: Nessa opção o banco é acessivel aos sysAdmins
 
-- ==================================================================
*/
ALTER DATABASE DemoDB SET EMERGENCY

ALTER DATABASE DemoDB SET ONLINE 


/* ==================================================================
--Data: 25/09/2018 
--Autor :Wesley Neves
--Observação:  nessa configuração não se pode fazer alterações no banco
 
-- ==================================================================
*/
ALTER DATABASE DemoDB SET READ_ONLY 
