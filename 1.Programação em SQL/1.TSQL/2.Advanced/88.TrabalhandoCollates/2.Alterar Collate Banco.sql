-- Altera o collate da base
-- Atenção: Procedimento colocará a base em modo mono-usuário até o término da alteração

ALTER DATABASE NOME_DA_BASE SET SINGLE_USER WITH ROLLBACK IMMEDIATE
 
ALTER DATABASE NOME_DA_BASE COLLATE Latin1_General_CI_AI
ALTER DATABASE NOME_DA_BASE SET MULTI_USER
GO