-- Altera o collate da base
-- Aten��o: Procedimento colocar� a base em modo mono-usu�rio at� o t�rmino da altera��o

ALTER DATABASE NOME_DA_BASE SET SINGLE_USER WITH ROLLBACK IMMEDIATE
 
ALTER DATABASE NOME_DA_BASE COLLATE Latin1_General_CI_AI
ALTER DATABASE NOME_DA_BASE SET MULTI_USER
GO