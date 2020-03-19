

/* ==================================================================
--Data: 04/06/2018 
--Observa��o:  Formas de se criar tabelas temporais
H� tr�s maneiras de criar uma tabela temporal com controle da vers�o do sistema relacionadas ao modo 
como a tabela de hist�rico � especificada:

Tabela temporal com uma tabela de hist�rico an�nimo: especifique o esquema da tabela atual e deixe o sistema 
criar a tabela de hist�rico correspondente com o nome gerado automaticamente.

Tabela temporal com uma tabela de hist�rico padr�o: especifique o nome do esquema de tabela de hist�rico e o 
nome da tabela e deixe o sistema criar tabela de hist�rico nesse esquema.

Tabela temporal com uma tabela de hist�rico definida pelo usu�rio criada antecipadamente: crie a tabela 
de hist�rico que melhor atenda �s suas necessidades e fa�a refer�ncia a essa tabela durante a cria��o da tabela temporal.
 
-- ==================================================================
*/

--1)

/*
Uma tabela temporal com controle da vers�o do sistema deve ter uma chave prim�ria definida e ter exatamente um 
PERIOD FOR SYSTEM_TIME definido com duas colunas datetime2, declaradas como GENERATED ALWAYS AS ROW START / END

Sup�e-se que as colunas PERIOD sempre s�o n�o anul�veis, mesmo se a nulidade n�o for especificada. 
Se as colunas PERIOD forem definidas explicitamente como anul�veis, a instru��o CREATE TABLE falhar�.
*/

CREATE TABLE Department (
    DeptID INT NOT NULL PRIMARY KEY CLUSTERED,
    DeptName VARCHAR(50) NOT NULL,
    ManagerID INT NULL,
    ParentDeptID INT NULL,
    StartDate DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    EndDate DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
    PERIOD FOR SYSTEM_TIME(StartDate, EndDate)) WITH(SYSTEM_VERSIONING =ON ,DATA_COMPRESSION =PAGE)
	;